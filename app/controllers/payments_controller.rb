class PaymentsController < ApplicationController
      
    def stripe_checkout
      # Check if the current user already has a Stripe Customer
      if current_user.stripe_customer_id.present?
        customer_id = current_user.stripe_customer_id
      else
        # Create a new Stripe Customer
        customer = Stripe::Customer.create(email: current_user.email)
        customer_id = customer.id
  
        # Save the customer_id to the user model for future use
        current_user.update(stripe_customer_id: customer_id)
      end

      # Create a Stripe Checkout session
      session = Stripe::Checkout::Session.create(
        payment_method_types: ['card'],
        customer: customer_id,  # Attach the customer to this session
        line_items: [{
          price_data: {
            currency: 'usd',
            unit_amount: current_user.site&.tier&.price.to_i * 100 ,  # Amount in cents ($20.00)
            product_data: { name: 'Pro Plan Subscription' }
          },
          quantity: 1
        }],
        mode: 'payment',  # Single payment mode
        success_url: "#{root_url}payments/success?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: "#{root_url}payments/cancel",
        payment_intent_data: {
          setup_future_usage: 'off_session'  # Save the card for future use
        }
      )
  
      # Redirect the user to the Stripe Checkout page
      redirect_to session.url, allow_other_host: true
    end
  
    def success
      # Retrieve the session using the session_id
      session = Stripe::Checkout::Session.retrieve({
        id: params[:session_id],
        expand: ['payment_intent.payment_method']  # Expand the payment method to get card details
      })
      
      
      # Access the payment intent (which contains the payment method details)
      payment_intent = session.payment_intent
      payment_method = payment_intent.payment_method
  
      # Access the card details (last4, brand, etc.)
      cardholder_name = payment_method.billing_details.name
      card = payment_method.card
      brand = card.brand
      last4 = card.last4
      exp_month = card.exp_month
      exp_year = card.exp_year

      # customer_id = current_user.stripe_customer_id # Replace with your actual customer ID

      # payment_methods = Stripe::PaymentMethod.list({
      #   customer: customer_id,
      #   type: 'card'
      # })

      # credit_cards = payment_methods.data
      # last_card = credit_cards.last
      # created_date = Time.at(last_card.created).to_date
      
      # credit_card_count = credit_cards.count


      CreditCard.create(user_id: current_user.id,created: Time.now, edited: Time.now, 
                              card_type: brand, last_four: last4, month: exp_month,
                              year: exp_year,created_with: 'StoreCard',visible: 1, edited_with: 'StoreCard',
                              edited_by: current_user.id, info_key: rand(1000..99999),created_by: current_user.id, label: cardholder_name) 
      subscription = Subscription.where(site_id: current_user.site&.id).first             
      site = Site.where(id: current_user.site&.id).first

      if subscription.blank?
         Subscription.create(site_id: site.id, subscription_date: Time.now, subscription_end_date: Time.now + 1.year )                               
        #  site.update(projects_count: 1, products_count: 0, users_count: 0) if site.present?
      else
         subscription.update(subscription_date: Time.now, subscription_end_date: Time.now + 1.year ) if subscription.present?                                
         site.update(projects_count: 0, products_count: 0, users_count: 0) if site.present?
      end      
      redirect_to root_path, notice: "Payment was successful! Card: #{brand} **** **** **** #{last4}, Expires #{exp_month}/#{exp_year}" 
  
    end
  
    def cancel
      redirect_to root_path, alert: "Try again later to pay."
    end

    def pay
    end  
end
  