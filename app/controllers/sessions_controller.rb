# TODO: Abstract default site ID to a config/user model
class SessionsController < ApplicationController

    # const_def :DEFAULT_SITE_ID, Site.first(site: 'RE|Furnish')&.id # Seattle
    DEFAULT_SITE_ID = Site.find_by(site: 'RE|Furnish')&.id

    # Login form
    def login
        render "login"
    end

    def register_site
        # @tiers = Tier.all(default: true)
        @tiers = Tier.where(default: true)
    end    

    def create_site
        site_name = params[:sitename]
        if Site.where(:conditions => ['LOWER(site) = ?', site_name.downcase])&.first
            flash.now[:alert] = "site already exists."
            return register_site
            # $LOG.debug "User signup failed: [%s]" % ['site already exists']
        else
            site = Site.create( site: site_name, created_at: Time.now, 
                     created_with: 'SiteMaintenance', updated_at: Time.now,
                     edited_with: 'save site', active: 'Active',tax_authority_id: 796, 
                     tier_id: params[:selected_tier].split('-')[1], location_id: 1)
            if site.persisted?
                flash.notice = "Site created successfully."
                return redirect_to root_path
            else
                flash.alert = "Error creating site."
                return register_site
            end
            
        end  
    end

    # Locate user via the three known SDN user logins
    def create
        account = params[:email]
        user    = User.locate(account)
      
        if user && user.valid_password?(params[:password])
            session[:user_id] = user.id
            user_authentication = UserAuthentication.where(user_id: user.id)&.last
            if user_authentication.blank?
              UserAuthentication.create(auth_code: SecureRandom.hex(16), created: Time.now, user_id: user.id)
            else
              user_authentication.update(auth_code: SecureRandom.hex(16))   
              session[:auth_code] = user_authentication.auth_code
            end    
            # unless session[:site_id]&.among?(Site.all(fields: [:id], active: 'Active').pluck(:id))
            #     session[:site_id] = user.site&.id || DEFAULT_SITE_ID
            # end

            unless Site.where(active: 'Active').exists?(id: session[:site_id])
                session[:site_id] = user.site&.id || DEFAULT_SITE_ID
            end
            sign_in(user)
            flash.notice = "Logged in!"
            skip_redirect_back_paths = [ login_path, update_password_path ]
            return redirect_to plp_path if params[:redirect_url] == 'inventory'
            # return URI(request.referrer).path.delete_suffix('/').among?(skip_redirect_back_paths) ? redirect_to(plp_path) : redirect_back(fallback_location: plp_path)
            (redirect_to(plp_path) && return) if URI(request.referrer).path.delete_suffix('/').in?(skip_redirect_back_paths); redirect_back(fallback_location: plp_path)

        else
            flash.now[:alert] = "Account or password is invalid."
            return login
        end
    end

    # Signup form
    def signup
        render "signup"
    end

    def check_site
        if site_exists?(params[:name])
            render json: { exists: true, message: 'Site already exists' }
        else
            render json: { exists: false }
        end
    end

    def check_username
        user_name = params[:name]
        if User.where('LOWER(username) = ?', user_name.downcase)&.first
            render json: { exists: true, message: 'User name already exists' }
        else
            render json: { exists: false }
        end
    end

    def create_account
        token = params['recaptcha_token'] || params['recaptcha_token_site']
    
        if verify_recaptcha(action: 'signup', minimum_score: 0.5, response: token) || session[:recaptcha] == true
                errors = []
                errors << 'Missing required input.' unless ['email', 'password', 'password_confirmation'].all? { |e| params.keys.include? e }
                errors << 'Email already exists.' if User.where(email: params[:email])&.first
                errors << 'UserName already exists.' if User.where(username: params[:username])&.first
                errors << 'Password must be longer than 8 characters.' if params[:password].length <= 8
                errors << 'Passwords did not match.' unless params[:password] == params[:password_confirmation]
                errors << 'Site already exist.' if site_exists?(params[:sitename])
                # errors << 'Invalid warehouse location.' unless params[:site_id].to_i.among?(all_sites_for_select.map{|a| a[1] })
                site = Site.create( site: params[:sitename], created: Time.now, 
                created_with: 'SiteMaintenance', edited: Time.now,
                edited_with: 'save site', active: 'Active',tax_authority_id: 796, 
                tier_id: params[:selected_tier].split('-')[1], location_id: 1)  if params[:sitename].present?

                errors << 'Site not created. try again' if site.blank? && params[:sitename].present?    
                # FIXME: Re-enable when we have the terms from legal
                # errors << 'Must agree to our terms.' unless params[:terms] == 'yes'

                if errors.any?
                    flash.alert = errors
                    @tiers = Tier.where(default: true)
                    session[:recaptcha] = true
                    if params[:sitename].present?
                        site.destroy if site.present?
                        render :register_site
                        return
                    else
                        render :signup
                        return
                    end
                end 

                user = User.new(
                    first_name: params[:first_name],
                    last_name:  params[:last_name],
                    email:      params[:email],
                    username:   params[:username],
                    password:   params[:password],
                    active:     'Active',
                    # password: nil,
                    site_id:    site.present? ? site.id : params[:site_id],    
                    # || DEFAULT_SITE_ID,
                    occupation: params[:shopper_type],
                    pulled_credit:  1,
                    join_date: Time.now,    
                    location_rights: site.present? ? site.id : params[:site_id]
                )
                params[:sitename].present? ? user.user_type = 'Employee' : user.user_type = 'Customer'  
                puts user.inspect+"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
                if user.save
                UserMembershipLevel.create_user_membership(user)
                # session[:user_id] = user.id
                User.save_rooms_subscriptions(user) 
                user_authentication = UserAuthentication.create(auth_code: SecureRandom.hex(16), created: Time.now, user_id: user.id)
                session[:auth_code] = user_authentication.auth_code

                address = Address.new(company: site.name, address1: params[:address], city: params[:city],
                                   state: params[:state], zipcode: params[:zip],table_name: 'sites', table_id: site.id) 
                                   address[:table_id] = site.id
                                   address[:table_name] = 'sites'                                    
                address.save
                user.update(billing_address_id:  address.id, telephone: params[:phone],
                            company_name: params[:sitename]) if address.present?
                site.update(created_by: user.id)  

                # default_rooms = Room.where(id: 1..20)

                # unless default_rooms.blank?
                #     default_rooms.each do |room|
                #         Room.create(
                #         name: room.name,
                #         zone: room.zone,
                #         token: room.token,
                #         position: room.position,
                #         user_id: user.id
                #         )
                #     end
                # end

                
                sign_in(user)

                if user.user_type == "Employee"
                    role = Role.where(role: 'Administrator').first
                    site.update(users_count: site.users_count.to_i + 1)
                    UserRole.create(user_id: user.id, role_id: role&.id)
                    redirect_to pay_path
                else
                    role = Role.where(role: 'Customer').first
                    UserRole.create(user_id: user.id, role_id: role&.id)  
                    redirect_to root_path    
                end

                Rails.logger.info "User account created: %s [id: %i, site: %i]" % [user.email, user.id, user.site_id]
                flash.notice = "Signup successful. You are logged in!"
                WelcomeMailer.new.send_welcome(user).deliver
                session[:recaptcha] = nil
                # return URI(request.referrer).path == signup_path ? redirect_to(plp_path) : redirect_back(fallback_location: plp_path)
            else
                # session[:recaptcha] = true
                # flash.alert = user.errors.inspect
                Rails.logger.debug "User signup failed: [%s]" % [user.errors.inspect]
                # return signup

                session[:recaptcha] = true
                
                flash.alert = user.errors.full_messages.join(', ')  
                site.destroy if site.present?
                if params[:sitename].present?
                    return register_site
                else
                    return signup
                end 

            end
        else
            redirect_to root_path, alert: 'reCAPTCHA failed!'
        end
    end

    # Forgot password form
    def forgot_password
        return redirect_to(account_path, notice: "Already logged in.") if user_signed_in?
        render
    end

    # Sends password reset email
    def send_reset_password_email
        user = User.locate(params[:email])
        notice_message = "Password reset email was sent to #{params[:email]} if it exists."
        return redirect_to(forgot_password_path, notice: notice_message) unless user

        reset_code = ::SDN::Utils::RefCode.generate(25)
        user.reset_code = reset_code

        unless user.save
            Rails.logger.error "Password reset code NOT saved for user: %s [code: %s] %s" % [ user.email, reset_code, user.errors.inspect ]
            return redirect_to(forgot_password_path, alert: 'Unable to request a password reset. Please try again.')
        end

        # Send password reset email
        email = PasswordMailer.new.send_reset_password(user, code: reset_code).deliver
        if email.errors.any?
            Rails.logger.error "Password reset email NOT sent for user: %s [%s]" % [ user.email, email.errors.inspect ]
            return redirect_to(forgot_password_path, alert: 'Unable to send reset email. Please try again.')
        else
            Rails.logger.info "Password reset email sent for user: %s" % [ user.email ]
            EmailLog.create_from_mail_message(email, email_type: 'Password Reset')
            return redirect_to(root_path, notice: notice_message)
        end
    end

    # Reset user password form
    def reset_password
        return redirect_to(forgot_password_path, alert: 'Invalid email/key combination. Please try again.') unless valid_reset_password_params?
        render
    end

    # Updates user password
    def update_password
        return redirect_to(forgot_password_path, alert: 'Invalid email/key combination. Please try again.') unless valid_reset_password_params?

        password = params[:password]
        password_confirmation = params[:password_confirmation]

        return redirect_back(fallback_location: reset_password_path, alert: 'Passwords do not match. Please double check and try again.') unless password == password_confirmation

        @user.password = password

        if @user.save
            Rails.logger.info "User password updated: %s" % [ @user.email ]

            email = PasswordMailer.new.send_password_changed(@user, changed_at: Time.zone.now).deliver
            if email.errors.any?
                Rails.logger.error "Password changed email NOT sent for user: %s [%s]" % [ @user.email, email.errors.inspect ]
            else
                Rails.logger.info "Password changed email sent for user: %s" % [ @user.email ]
                EmailLog.create_from_mail_message(email, email_type: 'Password Changed')
            end

            return create
        else
            Rails.logger.error "User password NOT updated: %s" % [ @user.email ]
            return redirect_back(fallback_location: reset_password_path, alert: 'Error updating password. Please try again.')
        end
    end

    # Sets the session's location/site
    def change_location
        site_id = params[:id].to_i

        # TODO: This is hacky - need to determine the correct way to handle this
        redirect = URI::parse(request.referrer).path.among?(['/checkout/process']) ? redirect_to(root_path) : redirect_back(fallback_location: root_path)

        return redirect if site_id == session[:site_id]

        sites = Site.all(active: 'Active')

        unless site_id.among?(sites.pluck('id'))
            flash.alert = "Invalid location selected."
        else
            session[:site_id] = site_id
            site_name = sites.find{ |s| s.id == site_id }.name
            site_name = site_id == 23 ? 'Seattle Closeout' : site_id == 24 ? 'Seattle' : site_name
            Rails.logger.info "Site changed to %s for %s." % [ site_name, @current_user&.email || 'guest@guest.log' ]
            flash.notice = "Location changed to %s." % [ site_name ]
        end

        return redirect
    end

    # Signs a user out but keeps their session in the DB
    # To completely destroy the session, use #destroy
    def logout
        sign_out(@current_user) 
        # binding.pry
        session[:user_id] = @current_user = nil
        if session['god']
            session[:god] = nil
            session[:impersonate] = nil
        end
        session[:auth_code] = nil
        redirect_to root_url, notice: "Logged out!"
    end

    # Destroys a user's session (equivalent to clearing cookies)
    # Useful for helping clear everything for a user
    def destroy
        session.destroy
        return redirect_to(root_path, notice: 'Session successfully destroyed.')
    end

    private
        def default_site_furnish
          Site.where(site: 'RE|Furnish').first&.id
        end    
        def valid_reset_password_params?
            email = params[:email]
            reset_code = params[:key]

            @user = User.locate(email)
            unless @user.reset_code == reset_code
                Rails.logger.error "Invalid attempt to reset password: [email: %s, key: %s, ip: %s]" % [ email, reset_code, request.remote_ip ]
                return false
            end

            return true
        end
        def site_exists?(name)
            # Site.where(:conditions => ['LOWER(site) = ?', name.to_s.downcase])&.first.present?
            Site.where('LOWER(site) = ?', name.to_s.downcase)&.first.present?

        end

end
