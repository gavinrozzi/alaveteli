require File.join(File.dirname(__FILE__), 'usage')
namespace :config_files do

    include Usage

    def convert_ugly(file, replacements)
        converted_lines = []
        ugly_var = /\!\!\(\*= \$([^ ]+) \*\)\!\!/
        File.open(file, 'r').each do |line|
            line = line.gsub(ugly_var) do |match|
                var = $1.to_sym
                replacement = replacements[var]
                if replacement == nil
                    raise "Unhandled variable in .ugly file: $#{var}"
                else
                    replacements[var]
                end
            end
            converted_lines << line
        end
        converted_lines
    end

    desc 'Convert Debian .ugly init script in config to a form suitable for installing in /etc/init.d'
    task :convert_init_script => :environment do
        example = 'rake config_files:convert_init_script DEPLOY_USER=deploy VHOST_DIR=/dir/above/alaveteli VCSPATH=alaveteli SITE=alaveteli SCRIPT_FILE=config/alert-tracks-debian.ugly'
        check_for_env_vars(['DEPLOY_USER',
                            'VHOST_DIR',
                            'SCRIPT_FILE'], example)

        script_file = ENV['SCRIPT_FILE']
        site = ENV.fetch('SITE', 'foi')

        replacements = {
            :user => ENV['DEPLOY_USER'],
            :vhost_dir => ENV['VHOST_DIR'],
            :vcspath => ENV.fetch('VCSPATH', 'alaveteli'),
            :site => site
        }

        daemon_name = File.basename(script_file, '-debian.ugly')
        replacements.update(:daemon_name => "#{ site }-#{ daemon_name }")
        converted = convert_ugly(script_file, replacements)
        rails_env_file = File.expand_path(File.join(Rails.root, 'config', 'rails_env.rb'))

        unless File.exists?(rails_env_file)
            converted.each do |line|
                line.gsub!(/^#\s*RAILS_ENV=your_rails_env/, "RAILS_ENV=#{Rails.env}")
                line.gsub!(/^#\s*export RAILS_ENV/, "export RAILS_ENV")
            end
        end

        converted.each do |line|
            puts line
        end
    end

    desc 'Convert Debian .ugly crontab file in config to a form suitable for installing in /etc/cron.d'
    task :convert_crontab => :environment do
        example = 'rake config_files:convert_crontab DEPLOY_USER=deploy VHOST_DIR=/dir/above/alaveteli VCSPATH=alaveteli SITE=alaveteli CRONTAB=config/crontab-example MAILTO=cron-alaveteli@example.org'
        check_for_env_vars(['DEPLOY_USER',
                            'VHOST_DIR',
                            'VCSPATH',
                            'SITE',
                            'CRONTAB'], example)
        replacements = {
            :user => ENV['DEPLOY_USER'],
            :vhost_dir => ENV['VHOST_DIR'],
            :vcspath => ENV['VCSPATH'],
            :site => ENV['SITE'],
            :mailto => ENV.fetch('MAILTO') { "cron-#{ ENV['SITE'] }@mysociety.org" }
        }
        convert_ugly(ENV['CRONTAB'], replacements).each do |line|
            puts line
        end
    end

end
