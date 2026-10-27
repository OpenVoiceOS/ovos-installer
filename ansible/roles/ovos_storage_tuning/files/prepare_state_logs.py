#!/usr/bin/env python3
"""Preserve legacy logs on disk before reclaiming space from state tmpfs."""
import os
from pathlib import Path
import shutil
import sys
import tempfile


def prepare_logs(state, archive, limit=1_000_000):
    state, archive = Path(state), Path(archive)
    for source in sorted(state.iterdir()):
        if source.is_symlink() or not source.is_file():
            continue
        rotated = '.log.' in source.name
        if not (source.name.endswith('.log') or rotated):
            continue
        if not rotated and source.stat().st_size <= limit:
            continue
        archive.mkdir(parents=True, exist_ok=True, mode=0o700)
        # Unique backups keep earlier diagnostics on repeat installer runs.
        fd, destination = tempfile.mkstemp(prefix=source.name + '-', dir=archive)
        try:
            with os.fdopen(fd, 'wb') as target, source.open('rb') as original:
                shutil.copyfileobj(original, target)
                target.flush()
                os.fsync(target.fileno())
        except BaseException:
            Path(destination).unlink(missing_ok=True)
            raise
        # Once copying succeeds, keep the backup even if reclamation fails.
        if rotated:
            source.unlink()
        else:
            # Retain the inode because a running service may have it open.
            with source.open('r+b') as current:
                current.truncate(0)
        print('archived ' + source.name)



if __name__ == '__main__':
    prepare_logs(sys.argv[1], sys.argv[2])
