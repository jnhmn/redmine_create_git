require 'redmine'


Rails.configuration.to_prepare do
  require_dependency 'create_git/projects_controller_patch'
end


Redmine::Plugin.register :redmine_create_git do
  name 'Redmine Create Git and SVN plugin'
  author 'Jan Hohmann, Martin DENIZET'
  url 'https://github.com/jnhmn/redmine_create_git'
  author_url 'http://martin-denizet.com'
  description 'Ease the creation of Git repositories when using Git Smart HTTP'
  version '0.2.0'

  requires_redmine :version_or_higher => '2.0.1'

  settings :default => {
      :gitignore => '',
      :git_repo_path => File.expand_path('../repos/git/', Rails.root),
      :svn_repo_path => File.expand_path('../repos/svn/', Rails.root),
      :repo_url => '',
      :branches => '',
      :enable_commit_hook => 0,
      :commit_hook_ssl => 1

  }, :partial => 'settings/create_git'

end
