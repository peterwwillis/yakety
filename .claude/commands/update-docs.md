# Update Documentation

Regenerate comprehensive README.md and ARCHITECTURE.md documentation by analyzing the current codebase and updating intermediate documentation files.

## Process

This command will:
1. **Analyze codebase in parallel** across 7 key areas of interest
2. **Update intermediate docs** in `docs/*.md` (incremental improvements)
3. **Synthesize final documentation** into README.md and ARCHITECTURE.md
4. **Preserve all files** for future reference and LLM context

## Command

Analyze the codebase to update comprehensive documentation. For each area, read any existing `docs/area-of-interest.md` file first and update/improve it based on the current codebase state rather than starting from scratch.

Issue the following Task calls in parallel to speed up the process:

**Project Overview** (`docs/project-overview.md`):
- Read existing `docs/project-overview.md` if it exists
- Analyze the project to understand purpose, functionality, and key technologies
- Look at root files, source structure, dependencies (especially whisper.cpp)
- Update/improve the existing content with any changes or new findings
- Output: Project name, purpose, main functionality, key technologies, target platforms

**Architecture Analysis** (`docs/architecture.md`):
- Read existing `docs/architecture.md` if it exists  
- Analyze source code architecture and organization
- Examine directory structure, key modules, component interactions, platform-specific code
- Update/improve existing content with current architecture state
- Output: Directory structure, key modules, component interactions, platform abstraction

**Build System** (`docs/build-system.md`):
- Read existing `docs/build-system.md` if it exists
- Analyze CMakeLists.txt files, build presets, dependencies, platform-specific requirements
- Update/improve existing content with current build configuration
- Output: Build system overview, presets, dependencies, platform-specific instructions

**Testing and Quality** (`docs/testing.md`):
- Read existing `docs/testing.md` if it exists
- Analyze test files, testing framework, code quality tools, CI/CD configuration
- Update/improve existing content with current testing setup
- Output: Testing framework, test organization, how to run tests, code quality tools

**Development Workflow** (`docs/development.md`):
- Read existing `docs/development.md` if it exists
- Analyze development conventions, code style, Git workflow, development environment
- Update/improve existing content with current conventions and practices
- Output: Code style, development environment, Git workflow, file organization

**Deployment and Distribution** (`docs/deployment.md`):
- Read existing `docs/deployment.md` if it exists
- Analyze packaging, distribution, installation procedures, platform-specific deployment
- Update/improve existing content with current deployment approach
- Output: Packaging approach, installation requirements, platform considerations, runtime deps

**Implementation Patterns** (`docs/patterns.md`):
- Read existing `docs/patterns.md` if it exists
- Analyze async work management, dialog abstractions, menu item implementations
- Examine threading patterns, platform abstraction patterns, error handling
- Update/improve existing content with current implementation patterns
- Output: Async patterns, dialog abstractions, menu patterns, platform abstractions

After all tasks complete, read all `docs/*.md` files and synthesize them into:
1. **README.md** - Concise, user-facing documentation covering quick start, features, build instructions, development guidelines
2. **ARCHITECTURE.md** - Deep technical documentation for developers and LLMs covering architecture, components, flows, build system, security

**Final Cleanup Pass**: Each agent should perform a final cleanup of their generated `.md` file to:
- Merge any duplicated content
- Remove information that doesn't belong in their specific area of interest
- Make content minimal yet comprehensive
- Ensure clarity and actionability

Requirements:
- Make both documents concise yet comprehensive enough for immediate understanding
- Structure for quick reference with clear sections and code examples  
- Ensure LLM-friendly organization and human readability
- Focus on actionable information for both humans and AI assistants
- Overwrite existing README.md and ARCHITECTURE.md without confirmation