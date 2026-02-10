# Contributing to OpenWRT Passwall Monitor

First off, thank you for considering contributing! 🎉

## How Can I Contribute?

### Reporting Bugs 🐛

**Before creating a bug report:**
- Check the [FAQ](README.md#-faq) section
- Search existing [issues](https://github.com/YounesRahimi/openwrt-passwall-monitor/issues)
- Try the troubleshooting steps in the README

**When creating a bug report, include:**
- Router model and specs (CPU cores, RAM)
- OpenWRT version
- Passwall core being used (xray, sing-box, etc.)
- Script configuration (thresholds)
- Relevant log excerpts from `/var/log/passwall_monitor.log`
- Steps to reproduce
- Expected vs actual behavior

### Suggesting Enhancements 💡

We welcome feature suggestions! Please:
- Check if it's already been suggested
- Explain the use case
- Describe how it would work
- Consider if it fits the project's scope (lightweight, simple monitoring)

### Testing on Different Routers 🧪

One of the most valuable contributions is testing on different router models:

1. Test the script on your router
2. Share your optimal thresholds
3. Report compatibility (works/doesn't work)
4. Submit your config as an example

**Format for router configs:**
```markdown
## Router Model: XYZ Router
- CPU: X cores, Y GHz
- RAM: ZMB
- OpenWRT: version
- Optimal CPU Threshold: X%
- Optimal RAM Threshold: YMB
- Notes: Any special considerations
```

### Code Contributions 👨‍💻

#### Development Setup

```bash
# Clone your fork
git clone https://github.com/YounesRahimi/openwrt-passwall-monitor.git
cd openwrt-passwall-monitor

# Create a branch
git checkout -b feature/your-feature-name
```

#### Coding Guidelines

1. **POSIX Compliance**: Script must work on busybox ash shell
   - No bash-specific features
   - Test with `sh -n script.sh` for syntax
   - Avoid GNU-specific utilities

2. **Style Guide**:
   - Use 4 spaces for indentation (no tabs)
   - Keep lines under 100 characters
   - Use meaningful variable names
   - Add comments for complex logic

3. **Error Handling**:
   - Check command exit codes
   - Handle missing files/processes gracefully
   - Log errors appropriately

4. **Performance**:
   - Minimize external command calls
   - Script should run in <0.1 seconds
   - Avoid unnecessary loops

#### Example Code Style

```bash
# Good
get_process_cpu() {
    local pid=$1
    local cpu=$(top -bn1 -p "$pid" | tail -n1 | awk '{print $7}')
    echo "$cpu"
}

# Bad (bash-specific)
get_process_cpu() {
    local pid=$1
    local cpu=$(top -bn1 -p "$pid" | tail -n1 | awk '{print $7}')
    echo $cpu  # Missing quotes
}
```

#### Testing Your Changes

1. **Test on actual OpenWRT router** (required)
2. Test with different Passwall cores
3. Verify log rotation works
4. Test restart cooldown
5. Check for memory leaks (run for 24+ hours)

```bash
# Syntax check
sh -n passwall-monitor.sh

# Test run
./passwall-monitor.sh

# Monitor for issues
tail -f /var/log/passwall_monitor.log
```

#### Commit Messages

Use clear, descriptive commit messages:

```bash
# Good
git commit -m "Add support for trojan-go core"
git commit -m "Fix RAM detection on routers with <256MB"
git commit -m "Improve log rotation performance"

# Bad
git commit -m "fix bug"
git commit -m "update"
git commit -m "changes"
```

#### Pull Request Process

1. Update README.md if you're adding features
2. Update CHANGELOG.md with your changes
3. Test on at least one OpenWRT router
4. Create PR with clear description:
   - What changed
   - Why it changed
   - How to test
   - Any breaking changes

**PR Template:**
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement

## Testing
- Router model tested: 
- OpenWRT version: 
- Test duration: 
- Results: 

## Checklist
- [ ] Code follows POSIX standards
- [ ] Tested on actual router
- [ ] Documentation updated
- [ ] CHANGELOG updated
```

### Documentation Improvements 📚

Documentation is crucial! Help by:
- Fixing typos
- Improving clarity
- Adding examples
- Translating to other languages
- Creating video tutorials
- Writing blog posts

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Welcome newcomers
- Accept constructive criticism
- Focus on what's best for the community
- Show empathy

### Unacceptable Behavior

- Harassment or discrimination
- Trolling or insulting comments
- Publishing others' private information
- Spam or off-topic discussions

## Recognition

Contributors will be:
- Listed in the README (if you want)
- Mentioned in release notes
- Given credit in commits

## Questions?

- 💬 [GitHub Discussions](https://github.com/YounesRahimi/openwrt-passwall-monitor/discussions)
- 📧 Create an issue labeled "question"

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for making this project better!** 🙏
