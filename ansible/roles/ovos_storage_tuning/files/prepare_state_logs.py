#!/usr/bin/env python3
"""Preserve legacy logs on disk before reclaiming space from state tmpfs."""
import argparse
import os
from pathlib import Path
import sys
import tempfile


def walk_error(error):
    """Unreadable state must fail archival rather than falsely enabling sync."""
    raise error


def regular_files(root):
    """Walk nested directories deterministically without following symlinks."""
    for directory, dirs, files in os.walk(root, followlinks=False, onerror=walk_error):
        dirs[:] = sorted(d for d in dirs if not (Path(directory) / d).is_symlink())
        for name in sorted(files):
            path = Path(directory) / name
            if not path.is_symlink() and path.is_file():
                yield path


def prune_archive(archive, reserve, max_bytes, max_files):
    """Expire oldest backups before reserving room for one bounded new backup."""
    files = sorted(regular_files(archive), key=lambda p: (p.stat().st_mtime_ns, str(p)))
    total = sum(p.stat().st_size for p in files)
    while files and (total + reserve > max_bytes or len(files) >= max_files):
        oldest = files.pop(0)
        total -= oldest.stat().st_size
        oldest.unlink()


def prepare_logs(state, archive, limit=1_000_000, archive_all=False,
                 max_archive_bytes=100_000_000, max_archive_files=100):
    """Archive nested logs, retaining the newest 100 MB across at most 100 files."""
    if max_archive_bytes < 1 or max_archive_files < 1:
        raise ValueError('archive limits must be positive')
    state, archive = Path(state), Path(archive)
    if archive.is_symlink() or archive.resolve().is_relative_to(state.resolve()):
        raise ValueError('archive must be a separate directory outside state')
    for source in regular_files(state):
        rotated = '.log.' in source.name
        if not (source.name.endswith('.log') or rotated):
            continue
        size = source.stat().st_size
        if not rotated and size <= limit and not archive_all:
            continue
        if archive_all and not rotated and size == 0:
            continue
        destination_dir = archive / source.relative_to(state).parent
        destination_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
        reserve = min(size, max_archive_bytes)
        prune_archive(archive, reserve, max_archive_bytes, max_archive_files)
        fd, destination = tempfile.mkstemp(prefix=source.name + '-', dir=destination_dir)
        try:
            with os.fdopen(fd, 'wb') as target, source.open('rb') as original:
                # Snapshot a bounded tail even when a running service appends.
                original.seek(max(0, size - reserve))
                remaining = reserve
                while remaining:
                    chunk = original.read(min(remaining, 1024 * 1024))
                    if not chunk:
                        break
                    target.write(chunk)
                    remaining -= len(chunk)
                target.flush()
                os.fsync(target.fileno())
        except BaseException:
            Path(destination).unlink(missing_ok=True)
            raise
        # Once copying succeeds, keep the backup even if reclamation fails.
        if rotated:
            source.unlink()
        else:
            with source.open('r+b') as current:
                current.truncate(0)
        print('archived ' + str(source.relative_to(state)))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('state')
    parser.add_argument('archive')
    parser.add_argument('--archive-all', action='store_true')
    parser.add_argument('--ready-file')
    args = parser.parse_args()
    try:
        if args.ready_file:
            Path(args.ready_file).unlink(missing_ok=True)
        prepare_logs(args.state, args.archive, archive_all=args.archive_all)
        if args.ready_file:
            Path(args.ready_file).touch()
    except Exception as error:
        print(f'Log archival failed; state sync remains disabled: {error}', file=sys.stderr)
        sys.exit(1)
