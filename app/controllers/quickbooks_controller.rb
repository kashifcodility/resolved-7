class QuickbooksController < ApplicationController
 
  def quickbooks_authenticate
    client = IntuitAccount.new.oauth2_client
        redirect_to client.auth_code.authorize_url(
        redirect_uri: quickbooks_oauth_callback_url,
        response_type: 'code',
        state: SecureRandom.hex(12),
        scope: 'com.intuit.quickbooks.accounting'
      ), allow_other_host: true
  end

  def oauth_callback
    if params[:state].present?

      redirect_uri = quickbooks_oauth_callback_url
      client = IntuitAccount.new.oauth2_client
      if resp = client.auth_code.get_token(params[:code], redirect_uri: redirect_uri)
        a = IntuitAccount.create(
            oauth2_access_token: resp.token,
            oauth2_refresh_token: resp.refresh_token,
            realm_id: params[:realmId],
            oauth2_access_token_expires_at: Time.current.utc + 1.hour,
            oauth2_refresh_token_expires_at: 100.days.from_now
          ) if IntuitAccount.count == 0
          redirect_to '/account', notice: 'Connected to QuickBooks successfully!'
      else
        redirect_to '/account', notice: 'Not connected. try to connect again!'
      end      
    end    
     
  end

end