class SvnCreator

  def self.create_svn(project, repo_identifier, is_default)
    repo_path_base = Setting.plugin_redmine_create_git['svn_repo_path']
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

    if project and create_repo(new_repo_path)
      repo = Repository.factory('Subversion')
      repo.project = project
      repo.url = "file://"+repo_path_base+new_repo_name
      repo.login = ''
      repo.password = ''
      repo.root_url = ''
      #If the checkout plugin is installed
      if (defined?(Checkout))
        #New checkout plugin configuration hash
        #TODO: Use Checkout plugin defaults
        repo.checkout_overwrite = '1'
        repo.checkout_display_command = Setting.send('checkout_display_command_Git')
        #Somehow it would not work using a simple Hash
        params = ActionController::Parameters.new({:checkout_protocols => [{
                                                                               'command' => 'svn checkout',
                                                                               'is_default' => '1',
                                                                               'protocol' => 'http',
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

  def self.create_repo(repo_fullpath)
    if File.exist?(repo_fullpath)
      Rails.logger.error "Repository in '#{repo_fullpath}' already exists!"
      raise I18n.t('errors.repo_already_exists', {:path => repo_fullpath})
    else
      #Clone the new repository to initialize it
      #FIXME: incompatible with Windows
      temporary_clone='/tmp/tmp_create_svn/'
      system("rm -Rf #{temporary_clone}")
      system("mkdir #{repo_fullpath}")
      system("cd #{repo_fullpath} && svnadmin create .")
      system("svn checkout file://#{repo_fullpath} #{temporary_clone}");
      system("mkdir #{temporary_clone}/trunk");
      system("mkdir #{temporary_clone}/branches");
      system("mkdir #{temporary_clone}/tags");
      system("cd #{temporary_clone} && svn add trunk branches tags && svn ci -m 'First Commit'");


      #Delete the temporary clone
      system("rm -Rf  #{temporary_clone}")

      # Give owner group write privileges to let dav server alter the files
      system("chmod -R g+w #{repo_fullpath}")
      Rails.logger.info 'Creation finished'
    end
    return true
  end
end
