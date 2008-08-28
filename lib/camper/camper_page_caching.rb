require 'fileutils'

module PageCaching
    def cached?(path)
        File.exists?(path) and !File.size(path).zero?
    end

    def ext_for_mime
        case @headers['Content-Type']
        when 'application/atom+xml'
            'xml'
        else
            'html'
        end
    end

    def name_for_resource(filename)
        if filename =~ /^(.*)\.(.*)$/
            filename
        else
            "#{filename}.#{ext_for_mime}"
        end
    end

    def cached
        if (env['REQUEST_URI'] =~ /^((.*)\/)?([^\/]*)$/)
            path = File.join(ROOT, 'cache', $1)
            file = File.join(path, ($3 == '' && $1 == '/' ? 'index.html' : name_for_resource($3)))
            unless cached?(file)
                FileUtils.mkdir_p(path)
                File.open(file, 'w') { |f| f.write yield.to_s }
            end
            @headers['X-Sendfile'] = file
        end
    end

    def sweep
        FileUtils.rm_rf Dir[File.join(ROOT, 'cache', '*')]
    end
end
