# Manual Test Plan for Chops

This document outlines manual test scenarios to validate functionality that automated tests cannot cover (UI interactions, workflows, visual verification).

## Pre-Release Testing Checklist

### Installation & Launch
- [ ] Fresh install on clean macOS 15+ system
- [ ] Upgrade from previous version
- [ ] App launches without crashes
- [ ] No permission errors on first launch
- [ ] Sparkle updater initializes correctly

### Skill Discovery & Scanning
- [ ] Skills detected from ~/.claude/skills/
- [ ] Skills detected from ~/.cursor/rules/
- [ ] Skills detected from ~/.codex/skills/
- [ ] Skills detected from other configured tools
- [ ] File watcher detects new skills added
- [ ] File watcher detects skill modifications
- [ ] File watcher detects skill deletions

### Sidebar Navigation
- [ ] "Skills" section shows all skills
- [ ] "Skills" section expands to show sources (repos/folders)
- [ ] Selecting a source filters skills correctly
- [ ] Selecting parent "Skills" shows all skills again
- [ ] "Agents" section shows agent items
- [ ] "Rules" section shows rule items
- [ ] "Favorites" shows only favorited items
- [ ] Tool sections (Claude, Cursor, etc.) show correct counts
- [ ] Collections section works correctly
- [ ] Servers section shows remote servers

### Multi-Selection & Batch Operations
- [ ] Click to select single skill
- [ ] Cmd+Click to add to selection
- [ ] Shift+Click to select range
- [ ] Selected skills show visual indicator
- [ ] Three-dot menu appears when source skills visible
- [ ] "Install Selected" enabled only when skills selected
- [ ] "Install Selected" opens install sheet with correct skills
- [ ] "Uninstall Selected" enabled only when skills selected
- [ ] "Uninstall Selected" removes managed installs
- [ ] "Install All" installs all visible source skills
- [ ] "Uninstall All" removes all managed installs
- [ ] Menu correctly shows disabled state

### Skill List View
- [ ] Skills display with correct names
- [ ] Skill descriptions visible
- [ ] Type badges show for mixed views (skill/agent/rule)
- [ ] Tool icons display correctly
- [ ] Source badges show for source-backed skills
- [ ] Install count badges show correctly
- [ ] Favorite star icons display
- [ ] Project names show in sidebar
- [ ] Search filters skills in real-time
- [ ] Search matches name, description, and content

### Skill Detail View
- [ ] Selected skill shows in detail pane
- [ ] Skill metadata displays correctly
- [ ] Content editor shows skill content
- [ ] Syntax highlighting works
- [ ] Markdown rendering works
- [ ] Tool source badges show
- [ ] Install locations list correctly
- [ ] Favorite button toggles state
- [ ] Edit button opens editor (if not read-only)
- [ ] Read-only skills show locked indicator

### Skill Editing
- [ ] Cmd+S saves changes to disk
- [ ] Changes persist after app restart
- [ ] Frontmatter updates correctly
- [ ] Content updates correctly
- [ ] Source-backed skills are read-only
- [ ] Plugin skills are read-only
- [ ] Validation prevents invalid frontmatter

### Creating New Skills
- [ ] "New Skill" creates skill file
- [ ] "New Agent" creates agent file
- [ ] "New Rule" creates rule file
- [ ] File saved to correct location
- [ ] Frontmatter generated correctly
- [ ] Skill appears in list immediately
- [ ] Created skill becomes selected

### Source Management
- [ ] Add local folder source
- [ ] Add GitHub repo source
- [ ] Sources list shows in sidebar
- [ ] Source sync button works
- [ ] Sync status shows (spinner/error)
- [ ] Remove source (with confirmation)
- [ ] Managed installs prevent removal

### Install Targets
- [ ] Install sheet shows available targets
- [ ] Target list includes all tools
- [ ] Selecting target installs skill
- [ ] Installed skills show badge count
- [ ] Uninstall removes symlink/copy
- [ ] Multiple targets can be selected
- [ ] Install summary shows results

### Collections
- [ ] Create new collection
- [ ] Add skill to collection
- [ ] Remove skill from collection
- [ ] Filter by collection
- [ ] Rename collection
- [ ] Delete collection (with confirmation)
- [ ] Collection icon selector works

### Search & Filtering
- [ ] Search box filters in real-time
- [ ] Search is case-insensitive
- [ ] Search matches name
- [ ] Search matches description
- [ ] Search matches content
- [ ] Clear search shows all skills
- [ ] Filter by tool shows correct subset
- [ ] Filter by kind (skill/agent/rule) works

### Context Menus
- [ ] Right-click skill shows context menu
- [ ] Favorite/Unfavorite toggles
- [ ] Install option for source skills
- [ ] Uninstall option for managed installs
- [ ] Make Global option for eligible skills
- [ ] Collections submenu works
- [ ] Show in Finder opens location
- [ ] Delete option (with confirmation)

### Agent Compose Panel
- [ ] Claude agent integration works
- [ ] Codex agent integration works
- [ ] Skill content sent as context
- [ ] User message sent to agent
- [ ] Response displays with formatting
- [ ] Diff view shows changes
- [ ] Accept applies changes
- [ ] Reject discards changes
- [ ] Markdown rendering in responses

### Remote Servers
- [ ] Add remote server
- [ ] Connect via SSH
- [ ] Skills sync from server
- [ ] Remote skills show server badge
- [ ] Sync button updates remote skills
- [ ] Error states display correctly
- [ ] Remote skills are read-only

### Settings & Preferences
- [ ] Tool paths configured correctly
- [ ] Custom scan paths added
- [ ] Theme changes apply immediately
- [ ] Sparkle update check works
- [ ] Settings persist across launches

### Error Handling
- [ ] Invalid skill files show error
- [ ] Missing tool binaries show warning
- [ ] Network errors handled gracefully
- [ ] Permission errors show dialog
- [ ] Invalid frontmatter shows warning
- [ ] Disk full errors handled

### Performance
- [ ] App launches in < 3 seconds
- [ ] Scanning 100+ skills completes quickly
- [ ] UI remains responsive during scan
- [ ] Search responds instantly
- [ ] No lag when switching skills
- [ ] Memory usage reasonable (< 200MB)

### Visual Regression
- [ ] Layout correct on different screen sizes
- [ ] Dark mode renders correctly
- [ ] Light mode renders correctly
- [ ] Icons render sharply
- [ ] Fonts are readable
- [ ] Colors match design
- [ ] Spacing consistent
- [ ] Badges aligned correctly

### Accessibility
- [ ] VoiceOver reads elements correctly
- [ ] Keyboard navigation works
- [ ] Focus indicators visible
- [ ] Color contrast sufficient
- [ ] Text size respects system settings

### Edge Cases
- [ ] No skills installed (empty state)
- [ ] Very long skill names
- [ ] Skills with special characters
- [ ] Symlinked skill directories
- [ ] Skills with large content (>1MB)
- [ ] Rapid file system changes
- [ ] Concurrent installs/uninstalls

## Regression Testing

After each release, verify:
1. All existing skills still load
2. Previously working features still work
3. No new crashes or errors
4. Performance hasn't degraded
5. UI layout hasn't broken

## Device Testing Matrix

Test on:
- [ ] macOS 15.0 (minimum supported)
- [ ] macOS 15.1
- [ ] macOS 15.2+
- [ ] Intel Macs
- [ ] Apple Silicon Macs

## Bug Reporting

When filing bugs, include:
1. macOS version
2. Chops version
3. Steps to reproduce
4. Expected behavior
5. Actual behavior
6. Screenshots/video if UI issue
7. Console logs if crash

## Notes

- Run this checklist before each release
- Add new test cases when bugs are found
- Update automated tests to cover manual scenarios where possible
- Document any known issues or workarounds
