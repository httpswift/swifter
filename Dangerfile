# send a welcome message for the user
message "Hey, @#{github.pr_author} 👋."

# Just to let people know
warn("PR is classed as Work in Progress.") if github.pr_title.include? "[WIP]"

# Warn when there is a big PR
warn("Big PR") if git.lines_of_code > 500

# ensure there is a summary for a PR
fail "Please provide a summary in the Pull Request description." if github.pr_body.length < 5

# Changelog entries are required for changes to library files.
fail("Please include a CHANGELOG entry. You can find it at [CHANGELOG.md](https://github.com/httpswift/swifter/blob/stable/CHANGELOG.md).") unless git.modified_files.include?("CHANGELOG.md") || git.added_files.include?("CHANGELOG.md")

# Don't accept PR on master for now
fail "Please re-submit this PR to stable, you're trying to merge the PR on master." if github.branch_for_base == "master"

# If these are all empty something has gone wrong, better to raise it in a comment
if git.modified_files.empty? && git.added_files.empty? && git.deleted_files.empty?
    fail "This PR has no changes at all, this is likely a developer issue."
end

# Run SwiftLint
swiftlint.config_file = '.swiftlint.yml'
swiftlint.lint_files

# Warn when new tests are added but the XCTestManifests wasn't updated to run on Linux
tests_added_or_modified = git.modified_files.grep(/XCode\/Tests/).empty? || git.added_files.grep(/XCode\/Tests/).empty?
xc_manifest_updated = !git.modified_files.grep(/XCode\/Tests\/XCTestManifests.swift/).empty?
if tests_added_or_modified && !xc_manifest_updated
  warn("It seems like you've added new tests to the library. If that's the case, please update the [XCTestManifests.swift](https://github.com/httpswift/swifter/blob/stable/XCode/Tests/XCTestManifests.swift) file running in your terminal the command `swift test --generate-linuxmain`.")

  # This is a temporary warning to remove the entry for the failed test until we solve the issue in Linux
  warn("If you ran the command `swift test --generate-linuxmain` in your terminal, please remove the line `testCase(IOSafetyTests.__allTests__IOSafetyTests),` from `public func __allTests() -> [XCTestCaseEntry]` in the bottom of the file. For more reference see [#366](https://github.com/httpswift/swifter/issues/366).")
end