"""Preservation checks for the explicitly invoked description compactor."""
import unittest

from sync.compact_skill_descriptions import compact


class CompactDescriptionTests(unittest.TestCase):
    def test_folded_description_preserves_metadata_and_body(self):
        source = ('---\nname: sample\ndescription: >-\n  Long scope.\n  More triggers.\n'
                  'metadata:\n  version: 2\n---\n\n# Skill\n\nKeep these instructions.\n')
        result = compact(source, 'Short scope.', 'Long scope. More triggers.')
        self.assertIn('description: "Short scope."\nmetadata:\n  version: 2\n---\n', result)
        self.assertTrue(result.endswith('\n# Skill\n\nKeep these instructions.\n'))
        self.assertIn('Long scope. More triggers.', result)
        self.assertEqual(result, compact(result, 'Short scope.', 'Long scope. More triggers.'))

    def test_quotes_unicode_and_body_delimiters(self):
        source = '---\nname: sample\ndescription: Old\n---\n# Skill\n---\nBody\n'
        result = compact(source, 'Use "quotes": café.', 'Old')
        self.assertIn('description: "Use \\"quotes\\": café."', result)
        self.assertTrue(result.endswith('# Skill\n---\nBody\n'))

    def test_missing_or_duplicate_field_is_rejected(self):
        for source in ['No frontmatter', '---\nname: a\n---\nBody',
                       '---\ndescription: one\ndescription: two\n---\nBody']:
            with self.subTest(source=source), self.assertRaises(ValueError):
                compact(source, 'New', 'Old')


if __name__ == '__main__':
    unittest.main()
