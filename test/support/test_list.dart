import 'dart:io';

const testListPath = 'testdata/konsou-test-list.db';

/// The test list is not in git, so tests that read it skip on a fresh clone.
final Object skipWithoutTestList = File(testListPath).existsSync()
    ? false
    : '$testListPath is not in git; copy it in to run this';
