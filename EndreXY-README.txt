Started 2022-08-06, after researching quite a bit in 2022-June.
-- 2022-12-02, copied from centiservice.github.io repository.

Github pages support for Jekyll:
 (Evidently Github pages is actually based on Jekyll, and Jekyll was initially made
 "by the former boss of Github" Tom Preston-Werner)
 https://docs.github.com/en/pages/setting-up-a-github-pages-site-with-jekyll/about-github-pages-and-jekyll
 https://docs.github.com/en/pages/setting-up-a-github-pages-site-with-jekyll/adding-a-theme-to-your-github-pages-site-using-jekyll

Use Minimal Mistakes Jekyll Theme:
 https://github.com/mmistakes/minimal-mistakes


Jekyll install for Ubuntu:
=> https://jekyllrb.com/docs/installation/ubuntu/

$ sudo apt-get install ruby-full build-essential zlib1g-dev
-> done, good

$
  echo '# Install Ruby Gems to ~/gems' >> ~/.bashrc
  echo 'export GEM_HOME="$HOME/gems"' >> ~/.bashrc
  echo 'export PATH="$HOME/gems/bin:$PATH"' >> ~/.bashrc
  source ~/.bashrc
-> done, good

$ gem install jekyll bundler
-> done, seemingly good

Quickstart:
=> https://jekyllrb.com/docs/
$ jekyll new myblog
-> done, "New jekyll site installed in /home/endre/myblog."
Note:
  Bundler: Bundle complete! 7 Gemfile dependencies, 31 gems now installed.
  Bundler: Use `bundle info [gemname]` to see where a bundled gem is installed.

$ cd myblog
$ bundle exec jekyll serve
-> done.
-> browsing to http://localhost:4000/
-> result: nice little blog.

--------------------------------------

Michael Rose of Minimal Mistakes has also made a new theme, "Basically Basic",
a replacement for the standard minimal theme of Jekyll.
This has somewhat good installation instructions.
  https://github.com/mmistakes/jekyll-theme-basically-basic

--------------------------------------


Trying to make a new site, using Minimal Mistakes:
https://github.com/mmistakes/minimal-mistakes

There is evidently a "Github remote theme starter" repo which can be cloned and
then tailored.

* Cloned this down to ~/git/mm-github-pages-starter
Trying..
$ bundle exec jekyll serve
-> error: Do "bundle install"

$ bundle install
-> done, seems ok

$ bundle exec jekyll serve
-> Got the error that evidently was expected:
  "GitHub Metadata: No GitHub API authentication could be found.
     Some fields may be missing or have incorrect data."

* Okay, so trying to just hammer this in to the centiservice.github.io repo.
(deleted .git, copied all over to centiservice.github.io, deleted mm-github..)

* Edited README.md to be centiservice-specific (only shows on repo, not site)

* Fix the local development situation.
$ bundle exec jekyll serve
-> Oh, rite. This is just a Warning. It actually serves just OK.
Should this not pull the info from the git config or something?
Googling. https://github.com/github/pages-gem/issues/399#issuecomment-301827749
-> Done, adding "github: [metadata]" to _config.yml evidently worked.
Wonder which metadata it now uses - mine, or mmistakes?

2022-08-07: Okay, so github evidently runs this, and I can develop locally.
Great.
Changing _config.yml, deleting all posts and adding one.

Done. The rest of the history will reside in git.

Endre, 2022-08-07.

