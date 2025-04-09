class DevController < ApplicationController

    # experiments
    def index
        # Test session functionality
        session[:iter] ||= 0
        @i = session[:iter] += 1

        # Test the flash functionality
        flash[:notice] = :unf if @i % 4 == 0

        # Test the session manip functionality
        if @i == 12
            renew_session
            flash[:notice] = "session renewed"
        end

        reset_session if @i > 24
    end

end
