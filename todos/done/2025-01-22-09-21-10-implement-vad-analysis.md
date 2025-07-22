Now I have a comprehensive understanding of the VAD implementation requirements for Yakety. Let me provide a detailed report of my findings.

## Detailed Findings: Voice Activity Detection (VAD) Implementation Requirements

### What VAD is According to whisper.cpp Documentation

Voice Activity Detection (VAD) is a preprocessing system integrated into whisper.cpp that:

1. **Detects Speech Segments**: Analyzes audio samples to identify portions that contain human speech versus silence or non-speech audio
2. **Reduces Processing Load**: Only the speech segments detected by VAD are extracted from the original audio and passed to Whisper for transcription, significantly speeding up the transcription process
3. **Uses Dedicated Models**: Requires a separate VAD model (currently Silero-VAD v5.1.2 is supported) that runs independently of the main Whisper model
4. **Provides Flexible Control**: Offers extensive configuration parameters to fine-tune speech detection behavior

### Current Audio Processing Pipeline in Yakety

The current audio processing pipeline follows this flow:

1. **Audio Capture** (`src/audio.c`):
   - Uses MiniAudio library for cross-platform audio recording
   - Fixed to Whisper requirements: 16kHz mono, float32 format
   - Records to memory buffer during key press/hold events
   - Atomic operations for thread-safe recording state management

2. **User Interaction** (`src/main.c`):
   - Key press starts recording via `audio_recorder_start()`
   - Key release triggers processing via `process_recorded_audio()`
   - Minimum recording duration check (0.1 seconds)
   - Recording cancellation on additional key presses

3. **Audio Processing** (`src/main.c` → `src/transcription.cpp`):
   - Retrieves recorded samples via `audio_recorder_get_samples()`
   - Passes raw audio to `transcription_process()` with all samples
   - No preprocessing or speech detection currently

4. **Transcription** (`src/transcription.cpp`):
   - Uses whisper.cpp's `whisper_full()` function directly
   - Processes entire audio buffer regardless of speech content
   - Post-processing includes text filtering and cleanup
   - Results automatically pasted to active application

### Where VAD Should Be Integrated

Based on the whisper.cpp integration and current architecture, VAD should be integrated at **two key points**:

#### Option 1: whisper_full_params Integration (Recommended)
The whisper.cpp library already supports VAD through `whisper_full_params` structure:
- Enable via `wparams.vad = true`
- Set VAD model path via `wparams.vad_model_path`
- Configure VAD parameters via `wparams.vad_params`

**Integration point**: In `transcription_process()` function in `/Users/badlogic/workspaces/yakety/src/transcription.cpp` at lines 144-161 where `whisper_full_params` is configured.

#### Option 2: Standalone VAD Processing
Implement VAD as a preprocessing step:
- Use whisper.cpp's standalone VAD API (`whisper_vad_*` functions)
- Process audio in `process_recorded_audio()` before calling transcription
- Extract speech segments and concatenate for Whisper processing

### Existing VAD Code and Preparation

**Ready-to-use components found**:

1. **VAD Model Available**: 
   - Pre-converted Silero VAD model: `/Users/badlogic/workspaces/yakety/whisper.cpp/models/for-tests-silero-v5.1.2-ggml.bin`
   - Download scripts available: `download-vad-model.sh` and `download-vad-model.cmd`

2. **whisper.cpp VAD API**: Complete VAD integration already implemented in whisper.cpp:
   - `struct whisper_vad_params` with configurable thresholds
   - `whisper_vad_context` for VAD model management
   - Integration with `whisper_full()` via parameters

3. **Build System Ready**: CMake already links all necessary whisper.cpp libraries that include VAD support

**No existing VAD code in Yakety**: The codebase currently has no VAD implementation - this is a completely new feature to add.

### Technical Requirements for Implementation

#### 1. Core Implementation Requirements
- **Add VAD model management** to `/Users/badlogic/workspaces/yakety/src/models.c`
- **Modify transcription parameters** in `/Users/badlogic/workspaces/yakety/src/transcription.cpp`
- **Add VAD preferences** to handle user configuration
- **Update audio processing pipeline** to support VAD workflow

#### 2. Configuration Parameters Needed
Based on whisper.cpp VAD implementation:
```c
struct whisper_vad_params {
    float threshold;               // Default: 0.5 (speech probability threshold)
    int   min_speech_duration_ms;  // Default: 250ms (minimum valid speech segment)
    int   min_silence_duration_ms; // Default: 100ms (minimum silence to split segments)
    float max_speech_duration_s;   // Default: FLT_MAX (auto-split long segments)
    int   speech_pad_ms;           // Default: 30ms (padding around speech segments)
    float samples_overlap;         // Default: 0.1f (overlap between segments)
};
```

#### 3. Model Management Requirements
- **VAD model loading**: Separate from Whisper model loading
- **Model fallback**: Handle missing VAD model gracefully
- **Model distribution**: Include VAD model in app bundles/distributions
- **Model path resolution**: Support both bundled and custom VAD models

#### 4. Performance Considerations
- **Memory usage**: VAD adds ~1MB model overhead
- **Processing speed**: VAD preprocessing may add ~50-100ms but saves time on silence
- **Thread safety**: VAD context must be properly managed in multi-threaded environment
- **Model caching**: VAD model should be loaded once and reused

#### 5. User Experience Requirements
- **Automatic VAD**: Enable by default with sensible parameters
- **Configuration UI**: Allow users to adjust VAD sensitivity if needed
- **Graceful fallback**: Work without VAD if model unavailable
- **Performance feedback**: Show time savings from VAD in logs

### Recommended Implementation Approach

**Phase 1 - Basic VAD Integration**:
1. Modify `transcription_process()` to enable VAD via `whisper_full_params`
2. Add VAD model to bundled resources
3. Update model loading system to handle VAD model
4. Test with default VAD parameters

**Phase 2 - Advanced Configuration**:
1. Add VAD preferences to allow user tuning
2. Implement VAD model fallback system
3. Add performance metrics logging
4. Optimize VAD parameters for speech-to-text use case

This implementation would significantly improve Yakety's performance by avoiding transcription of silence and background noise, while maintaining the existing user experience.

Perfect! Now I have a comprehensive understanding of the current Yakety transcription implementation. Let me provide you with a detailed analysis:

## Current Transcription Implementation Analysis

### 1. Current whisper_full_params Usage and Configuration

**Location**: `src/transcription.cpp` lines 144-161

The current implementation uses these whisper parameters:
```cpp
struct whisper_full_params wparams = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
wparams.print_realtime = false;
wparams.print_progress = false; 
wparams.print_timestamps = false;
wparams.print_special = false;
wparams.translate = false;
wparams.language = g_language;  // Configurable language
wparams.n_threads = n_threads;  // Auto-calculated optimal thread count
wparams.offset_ms = 0;
wparams.duration_ms = 0;
```

**Context Parameters** (lines 81-90):
```cpp
struct whisper_context_params cparams = whisper_context_default_params();
cparams.flash_attn = true;  // Flash Attention enabled
cparams.use_gpu = true;     // GPU acceleration enabled
```

### 2. Model Loading and Management Patterns

**Location**: `src/models.c` - THE ONE AND ONLY MODEL LOADING FUNCTION

The model system has a robust fallback mechanism:
- **Primary**: Uses user-specified model from preferences (`preferences_get_string("model")`)
- **Fallback**: Falls back to bundled base model if user model fails
- **Error Handling**: Removes corrupted models and shows overlay messages
- **Preferences Integration**: Saves/loads model path from config

**Key Features**:
- Thread-safe with mutex protection (`ctx_mutex`)
- Automatic model cleanup on failure
- Language setting from preferences (`preferences_get_string("language")`)

### 3. Configuration/Preferences System

**Location**: `src/preferences.c/h`

The preferences system is a robust INI-based configuration:
- **File Location**: `~/.yakety/config.ini` (platform-specific config dir)
- **Current Settings**:
  - `model`: Path to Whisper model (empty = use bundled)
  - `language`: Transcription language (default: "en")
  - `launch_at_login`: Auto-start setting
  - `KeyCombo`: Hotkey combination

**API Available**:
- `preferences_get_string/int/bool(key, default)`
- `preferences_set_string/int/bool(key, value)`
- `preferences_save()` - Persists to disk
- Thread-safe with mutex protection

### 4. Where VAD Integration Would Fit Most Naturally

Based on the current architecture, VAD integration should occur at **two levels**:

#### Level 1: Whisper Integration (Recommended Primary Approach)
**Location**: `src/transcription.cpp` in `transcription_process()` function around line 144

The whisper.cpp library already has VAD support built-in. This would be the cleanest integration:
```cpp
// Add VAD parameters to existing whisper_full_params
wparams.vad = true;
wparams.vad_model_path = vad_model_path;  // From preferences
wparams.vad_params = whisper_vad_default_params();  // Configurable
```

#### Level 2: Pre-processing Integration (Alternative/Additional)
**Location**: `src/main.c` in `process_recorded_audio()` around line 196

For more control, VAD could pre-process audio before sending to Whisper:
```cpp
// Before calling transcription_process()
float *filtered_samples = vad_filter_audio(samples, sample_count, vad_threshold);
if (filtered_samples && filtered_sample_count > 0) {
    char *text = transcription_process(filtered_samples, filtered_sample_count, 16000);
    // ... continue
}
```

#### Level 3: Preference Integration
**Location**: `src/preferences.c` default preferences (line 39-44)

Add VAD settings to the configuration system:
```c
set_entry("vad_enabled", "true");
set_entry("vad_threshold", "0.5"); 
set_entry("vad_min_speech_duration_ms", "250");
set_entry("vad_min_silence_duration_ms", "100");
```

### 5. Existing Logging and Performance Measurement

**Location**: Throughout `src/transcription.cpp` and `src/main.c`

The codebase has extensive performance logging already:
- **Timing Measurements**: Uses `utils_now()` for precise timing
- **Whisper Model Loading**: Logs loading duration
- **Transcription Pipeline**: Times individual steps:
  - Audio stop: `stop_duration`
  - Sample retrieval: `get_samples_duration` 
  - Whisper inference: `whisper_duration`
  - Full transcription: `transcribe_duration`
  - Clipboard operations: `clipboard_duration`
  - Total pipeline: `total_time`

**Example Logging Output**:
```
⏱️  Whisper inference took: 245 ms
⏱️  Full transcription pipeline took: 267 ms  
⏱️  Total time from stop to paste: 289 ms
```

### 6. Recommended VAD Integration Approach

Given this analysis, I recommend **Level 1 integration** using whisper.cpp's built-in VAD support:

1. **Add VAD model management** to `src/models.c` alongside existing Whisper models
2. **Add VAD preferences** to `src/preferences.c` with sensible defaults
3. **Integrate VAD parameters** into `transcription_process()` in `src/transcription.cpp`
4. **Extend existing performance logging** to include VAD timing metrics
5. **Use the existing overlay system** to show "Filtering audio..." status

This approach leverages:
- Existing robust model loading system
- Established preferences architecture  
- Current performance measurement framework
- Thread-safe design patterns already in place
- Whisper.cpp's optimized VAD implementation

The integration would be minimally invasive and follow existing code patterns perfectly.