- sometimes when i press the keycombo, recording starts and transcriptions and pasting happens, but i never see the overalay. the logs do say this:
    ```
    [2025-07-18 15:50:30] INFO: Overlay show requested for: Recording
    [2025-07-18 15:50:30] INFO: Overlay window exists, showing
    [2025-07-18 15:50:32] INFO: 🔴 Recorded for 1.96 seconds
    [2025-07-18 15:50:32] INFO: ⏱️  Audio stop took: 11 ms
    [2025-07-18 15:50:32] INFO: ⏱️  Getting audio samples took: 0 ms (30429 samples)
    [2025-07-18 15:50:32] INFO: 🧠 Starting transcription of 1.90 seconds of audio...
    [2025-07-18 15:50:32] INFO: 🧠 Transcribing 30429 audio samples (1.90 seconds) using language: en
    [2025-07-18 15:50:32] INFO: ⏱️  Whisper inference took: 91 ms
    [2025-07-18 15:50:32] INFO: ✅ Transcription complete: "This is a test. "
    [2025-07-18 15:50:32] INFO: ⏱️  Total transcription process took: 91 ms
    [2025-07-18 15:50:32] INFO: ⏱️  Full transcription pipeline took: 92 ms
    [2025-07-18 15:50:32] INFO: 📝 "This is a test. "
    [2025-07-18 15:50:32] INFO: ✅ Text pasted! (clipboard operations took 102 ms)
    [2025-07-18 15:50:32] INFO: ⏱️  Total time from stop to paste: 206 ms
    [2025-07-18 15:50:32] INFO: Overlay show requested for: Transcribing
    [2025-07-18 15:50:32] INFO: Overlay window exists, showing
    This is a test.
    ```
- Whisper V3 Turbo model will output "Thank You" if there was silence.