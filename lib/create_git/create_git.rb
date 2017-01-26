class GitCreator

  def self.create_git(project, repo_identifier, is_default)
    repo_path_base = Setting.plugin_redmine_create_git['git_repo_path']
    repo_path_base += '/' unless repo_path_base[-1, 1]=='/'

    repo_url_base = Setting.plugin_redmine_create_git['repo_url']
    if (defined?(Checkout) and not repo_url_base.nil?)
      repo_url_base += '/' unless repo_url_base[-1, 1]=='/'
    end

    project_identifier = project.identifier

    new_repo_name = project_identifier
    new_repo_name += ".#{repo_identifier}" unless repo_identifier.empty?

    new_repo_path = repo_path_base + new_repo_name


    Rails.logger.info "Creating repo in #{new_repo_path} for project #{project.name}"

    if project and create_repo(new_repo_path, project)
      repo = Repository.factory('Git')
      repo.project = project
      repo.url = repo_path_base+new_repo_name
      repo.login = ''
      repo.password = ''
      repo.root_url = new_repo_path
      #If the checkout plugin is installed
      if (defined?(Checkout))
        #New checkout plugin configuration hash
        #TODO: Use Checkout plugin defaults
        repo.checkout_overwrite = '1'
        repo.checkout_display_command = Setting.send('checkout_display_command_Git')
        #Somehow it would not work using a simple Hash
        params = ActionController::Parameters.new({:checkout_protocols => [{
                                                                               'command' => 'git clone',
                                                                               'is_default' => '1',
                                                                               'protocol' => 'Git',
                                                                               'fixed_url' => repo_url_base+new_repo_name,
                                                                               'access' => 'permission'}]
                                                  }) unless repo_url_base.nil?

        repo.checkout_protocols = params[:checkout_protocols] if params

      end
      #TODO: Use Redmine defaults
      repo.extra_info = {'extra_report_last_commit' => '0'}
      repo.identifier = repo_identifier
      repo.is_default = is_default
      return repo
    end

  end

  def self.create_repo(repo_fullpath, project)
    if File.exist?(repo_fullpath)
      Rails.logger.error "Repository in '#{repo_fullpath}' already exists!"
      raise I18n.t('errors.repo_already_exists', {:path => repo_fullpath})
    else
      #Clone the new repository to initialize it
      #FIXME: incompatible with Windows
      temporary_clone='/tmp/tmp_create_git/'
      system("rm -Rf #{temporary_clone}")
      system("mkdir #{repo_fullpath}")
      system("cd #{repo_fullpath} && git init --bare")
      system("git clone #{repo_fullpath} #{temporary_clone}");

      File.open("#{temporary_clone}/.gitignore", 'w') { |f| f.write(Setting.plugin_redmine_create_git['gitignore']) }
      #Make first commit
      #TODO: Make message configurable
      system("cd #{temporary_clone} && git add .gitignore && git commit -m 'First Commit' && git push origin master");
      #Create branches
      Setting.plugin_redmine_create_git['branches'].gsub(/\r/, '').split(/\n/).each do |branch|
        Rails.logger.info "Adding branch #{branch}"
        system("cd #{temporary_clone} && git checkout -b #{branch} && git push origin #{branch}");
      end

      # Create post-commit hook to inform redmine about changes
      File.open("#{repo_fullpath}/hooks/post-receive", 'w') { |f|
        f << "#!/bin/sh\n"
        f << "curl \"https://#{Setting.host_name}/sys/fetch_changesets?key=#{Setting.sys_api_key}&id=#{project.identifier}\""
      }

      #Delete the temporary clone
      system("rm -Rf  #{temporary_clone}")

      Rails.logger.info 'Creation finished'
    end
    return true
  end
end
