# Upstreaming patch 0013

Target: a merge request against `master` at https://code.videolan.org/videolan/vlc (the GitHub
repository is a mirror and takes no pull requests). Submit from Dave's VideoLAN GitLab account.

## Title

demux: avformat: keep subtitle tracks out of the PCR

## Description

A sparse subtitle track's last timestamp lags the audio and video by up to several seconds and
jumps forward with each cue. `Demux()` takes the PCR as the minimum over every track with an ES
that is within ten seconds of the newest, so with such a track present the PCR sits on the last
cue and advances in steps larger than `CR_MAX_GAP`. The core reads each step as a discontinuity
(`clock gap, unexpected stream discontinuity`) and re-bases, so the demuxer is never paced. On a
fast HTTP source the video decoder's fifo fills to its cap and is reset (`fifo full (data not
consumed quickly enough), resetting fifo!`), and the picture resumes minutes ahead of the sound.

The patch leaves SPU tracks out of the minimum and the maximum whenever an audio or video track
has an ES. A subtitle-only input keeps the previous behaviour. Subtitle packets are still sent with
their own timestamps; only the clock no longer waits for them.

Reproduced with a Matroska file (H.264 1080p at about 7 Mbps, AAC, one text subtitle track with
cues 0.5 to 3 s apart) over HTTP from a server delivering well above the stream's bitrate, through
libvlc 4 with `:demux=avformat` and `:network-caching=10000`:

| | before | after |
|---|---|---|
| `clock gap, unexpected stream discontinuity` lines, first 600 s | (fill in from the harness) | (fill in) |
| `fifo full … resetting fifo` resets, first 600 s | (fill in) | (fill in) |
| pictures lost | (fill in) | (fill in) |
| bytes read ahead of bytes played at 600 s | (fill in) | (fill in) |

libvlc's own Matroska demuxer, which does not count the subtitle track in its PCR, plays the same
file with zero clock gaps and read-ahead bounded at about 17 MiB, which is the behaviour this change
gives the avformat demuxer.

## Evidence to attach

- The two harness outputs (`.out`) and the two libvlc logs with the stream address redacted
  (`tools/vlc-harness` in the app repository redacts it).
- `ffprobe -show_streams` of the file (codec, time base and cue spacing of the subtitle track).

## Steps

1. `git format-patch` is already done: `libvlc/patches/0013-…patch` applies to `fd814768b` and to
   `master` (the file is identical, checked 2026-10-31).
2. Push a branch to a fork on code.videolan.org, open the MR with the text above, label `Demux`.
3. Note the MR link here and in the app repository's follow-ups (item 24).
