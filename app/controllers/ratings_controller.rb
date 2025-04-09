class RatingsController < ApplicationController
    before_action :require_login
    def create
        @rating = current_user.ratings.new(ratings_params)
        if @rating.save
            redirect_to account_order_path(params[:order_id]) || root_path, notice: 'Review submitted successfully.'
        else
            redirect_to account_order_path(params[:order_id]) || root_path, error: 'something went wrong.'
        end
    end
    private
    def ratings_params
        params.permit(:product_id, :order_id, :review_star)
    end
end
