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

Measured 2026-10-31 with VideoLAN's VLCKit nightly of 2026-08-31 (VLC `fd814768b` plus VLCKit's
twelve patches) against the same build plus this patch, 600 s each, same file, same server, ten
minutes apart:

| | before | after |
|---|---|---|
| `clock gap, unexpected stream discontinuity` lines | 1,410 | 0 |
| `ES_OUT_SET_PCR … late` and `ES_OUT_RESET_PCR` lines | 32 | 0 |
| `fifo full … resetting fifo` resets | 1 | 0 |
| picture freezes / clock jumps seen by the harness | 3 / 5 | 0 / 0 |
| pictures lost | 158 | 0 |
| bytes read in 600 s (the stream plays about 500 MiB in that time) | 1,211 MiB | 475 MiB |
| input rate at 600 s | edge speed | 288 KiB/s, the stream's own rate |

libvlc's own Matroska demuxer, which does not count the subtitle track in its PCR, plays the same
file with zero clock gaps and read-ahead bounded at about 17 MiB, which is the behaviour this change
gives the avformat demuxer.

## Evidence to attach

Prepared on the Mac mini in the session scratchpad (`…/scratchpad/vlc-mr/`; regenerate from
`tools/vlc-harness` in the app repository if gone): the two harness outputs and the two libvlc
logs, 600 s each. The harness redacts the stream path; the copies also replace the provider's
host with `provider.example` (check with `grep -c trxdnscloud` before attaching: must be 0).
`MR.md` in the same directory holds the title and body above. No ffprobe on the Mac; the libvlc
logs' `adding es` lines (`video codec = h264`, `audio codec = mp4a`, `subtitle codec = undf`)
give the track list.

## Steps

1. The patch is ready: `libvlc/patches/0013-…patch` applies to `fd814768b` and to `master`
   (`modules/demux/avformat/demux.c` is identical at both; checked against master `c783406` of
   2026-10-19 on 2026-11-01). The VLC checkout at `~/github/vlckit-scratch/vlc` has branch
   `avformat-spu-pcr` = `upstream/master` + the commit, authored `Dave Horsey <dave@cloudunifi.com>`.
2. Account: register natively at https://code.videolan.org/users/sign_up (name, username, email,
   password, captcha), then confirm the email. The "Sign in with GitHub" button refuses an
   account that does not already exist ("Create an account in code.videolan.org first, and then
   connect it to your GitHub account", seen 2026-11-01); link GitHub afterwards under
   Preferences → Account → Connected accounts if wanted. If the new account sits at "pending
   approval", mail videolan at videolan.org as the sign-up page says.
3. Fork https://code.videolan.org/videolan/vlc with the Fork button (personal fork:
   `code.videolan.org/<username>/vlc`). Add an SSH key under Preferences → SSH Keys, or use HTTPS
   with a personal access token (Preferences → Access Tokens, scope `write_repository`).
4. Push the branch:
   ```sh
   cd ~/github/vlckit-scratch/vlc
   git remote add fork git@code.videolan.org:<username>/vlc.git
   git push fork avformat-spu-pcr
   ```
   GitLab prints a "create a merge request" link in the push output; otherwise open the fork's
   Merge requests page and choose source `avformat-spu-pcr`, target `videolan/vlc:master`.
5. Fill the MR: title and body from `MR.md`, tick "Allow commits from members who can merge",
   drag the four evidence files into the description. Pick a `Demux` label if the picker offers
   one; maintainers set labels otherwise.
6. CI runs on the MR ("CI and discussions should be resolved before a Merge Request can be
   merged", VLC README). Review comments arrive at the GitHub account's primary email.
7. Note the MR link here and in the app repository's follow-ups (item 24).
