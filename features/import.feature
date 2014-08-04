Feature: Import content.

  Scenario: Basic export then import
    Given a WP install

    When I run `wp user create testuser testuser@example.com --role=editor`
    And I run `wp post generate --post_type=post --count=3 --post_author=testuser`
    And I run `wp post generate --post_type=page --count=2 --post_author=testuser`
    When I run `wp post list --post_type=any --format=count`
    Then STDOUT should be:
      """
      7
      """

    When I run `wp export`
    And save STDOUT 'Writing to file %s' as {EXPORT_FILE}

    When I run `wp site empty --yes`
    Then STDOUT should not be empty

    When I run `wp post list --post_type=any --format=count`
    Then STDOUT should be:
      """
      0
      """

    When I run `wp plugin install wordpress-importer --activate`
    Then STDOUT should not be empty

    When I run `wp import {EXPORT_FILE} --authors=skip`
    Then STDOUT should not be empty

    When I run `wp post list --post_type=any --format=count`
    Then STDOUT should be:
      """
      7
      """

  Scenario: Control importer verbosity
    Given a WP install

    When I run `wp export`
    And save STDOUT 'Writing to file %s' as {EXPORT_FILE}

    When I run `wp site empty --yes`
    Then STDOUT should not be empty

    When I run `wp plugin install wordpress-importer --activate`
    Then STDOUT should not be empty

    When I run `wp import {EXPORT_FILE} --authors=skip --quiet`
    Then STDOUT should be empty

    When I run `wp import {EXPORT_FILE} --authors=skip`
    Then STDOUT should contain:
      """
      already exists.
      """

    When I run `sed -i.bak s/post_type\>post/post_type\>postapples/g {EXPORT_FILE}`
    Then STDERR should be empty

    When I try `wp import {EXPORT_FILE} --authors=skip`
    Then STDERR should contain:
      """
      Invalid post type
      """

  Scenario: Export and import a directory of files
    Given a WP install
    And I run `mkdir export-posts`
    And I run `mkdir export-pages`

    When I run `wp post generate --count=49`
    When I run `wp post generate --post_type=page --count=49`
    And I run `wp post list --post_type=post,page --format=count`
    Then STDOUT should be:
      """
      100
      """

    When I run `wp export --dir=export-posts --post_type=post`
    When I run `wp export --dir=export-pages --post_type=page`
    Then STDOUT should not be empty

    When I run `wp site empty --yes`
    Then STDOUT should not be empty

    When I run `wp post list --post_type=post,page --format=count`
    Then STDOUT should be:
      """
      0
      """

    When I run `find export-* -type f | wc -l`
    Then STDOUT should be:
      """
      2
      """

    When I run `wp plugin install wordpress-importer --activate`
    And I run `wp import export-posts --authors=skip --skip=image_resize`
    And I run `wp import export-pages --authors=skip --skip=image_resize`
    Then STDOUT should not be empty

    When I run `wp post list --post_type=post,page --format=count`
    Then STDOUT should be:
      """
      100
      """
