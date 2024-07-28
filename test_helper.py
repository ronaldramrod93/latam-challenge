import unittest
from helper import build_query


class TestBuildQuery(unittest.TestCase):

    def test_build_query_ok(self):
        self.assertEqual(
            build_query("column", "myproject", "my_dataset", "my_table"),
            "SELECT column FROM `myproject.my_dataset.my_table` LIMIT 10"
        )

    def test_build_query_fail(self):
        self.assertNotEqual(build_query("", "", "", ""), "")


if __name__ == '__main__':
    unittest.main()
