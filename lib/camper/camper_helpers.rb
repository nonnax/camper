#!/usr/bin/env ruby
#
#       $Id$
#
#       Copyright 2007 nonnax <ironald@gmail.com>
#
#       This program is free software; you can redistribute it and/or modify
#       it under the terms of the GNU General Public License as published by
#       the Free Software Foundation; either version 2 of the License, or
#       (at your option) any later version.
#
#       This program is distributed in the hope that it will be useful,
#       but WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#       GNU General Public License for more details.
#
#       You should have received a copy of the GNU General Public License
#       along with this program; if not, write to the Free Software
#       Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#       MA 02110-1301, USA.
#
#       http://groups.google.com/group/object_id
#

module CampingHelpers

    def ago(from)
        #stolen from Rails DateHelper
        t = (((Time.now - from).abs)/60).round
        case t
        when 0..1            then 'less than a minute'
        when 2..44           then "#{t} minutes"
        when 45..89          then 'about 1 hour'
        when 90..1439        then "about #{(t.to_f / 60.0).round} hours"
        when 1440..2879      then '1 day'
        else                      "#{(t / 1440).round} days"
        end + ' ago'
    end
    # backwards compatibility with Pre-Camping 2.0 apps
    def env
        @env
    end

    def un(text)
        Rack::Utils.unescape(text)
    end
    # See AR validation documentation for details on validations.
    def errors_for(o);
        mab do
         ul.errors { o.errors.each_full { |er| li er } }
        end if o.errors.any?
    end

    # stolen from linkr o_O
    # module Controllers must provide a New class or just roll your own
    def bookmarklet
        text 'Drag the following link to your toolbar to submit with a single click: '
        a 'bookmark-it!', :href =>"javascript:location.href='http:#{URL(New)}?page_link='+encodeURIComponent(location.href)+'&description='+encodeURIComponent(document.title)+'&body='+encodeURIComponent(window.getSelection())"
    end

   # Here's a little technique you can use to support multiple layouts within a Camping app.
    def layout
        @current_layout ||= :default_layout
        send("#{@current_layout}"){ yield }
    end

    def use_layout(layout_method=:layout_method)
        self.class.class_eval do
            alias_method layout_method, :layout
        end
    end

end
