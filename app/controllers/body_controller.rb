# app/controllers/body_controller.rb:
# Show information about a public body.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: body_controller.rb,v 1.7 2008-02-27 13:59:51 francis Exp $

class BodyController < ApplicationController
    # XXX tidy this up with better error messages, and a more standard infrastructure for the redirect to canonical URL
    def show
        if MySociety::Format.simplify_url_part(params[:url_name]) != params[:url_name]
            redirect_to :url_name =>  MySociety::Format.simplify_url_part(params[:url_name])
            return
        end

        @public_bodies = PublicBody.find(:all,
            :conditions => [ "url_name = ?", params[:url_name] ])
        if @public_bodies.size > 1
            raise "Two bodies with the same URL name: " . params[:url_name]
        end
        # If none found, then search the history of short names, and do a redirect
        if @public_bodies.size == 0
            @public_bodies = PublicBody.find(:all,
                :conditions => [ "id in (select public_body_id from public_body_versions where url_name = ?)", params[:url_name] ])
            if @public_bodies.size > 1
                raise "Two bodies with the same historical URL name: " . params[:url_name]
            end
            if @public_bodies.size == 0
                raise "None found" # XXX proper 404
            end
            redirect_to show_public_body_url(:url_name => @public_bodies[0].url_name)
        end
        @public_body = @public_bodies[0]
    end

    def list
        @public_bodies = PublicBody.paginate :order => "name", :page => params[:page], :per_page => 25
    end

 end
