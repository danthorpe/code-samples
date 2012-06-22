class TrueLocalAPI  < Sinatra::Base

# Filters
# --------------------------------------------------------------------------

    before do

        if valid_client?(request)

            # Authenticate the request
            @auth = authenticate(request)

        else
            halt 401, {:error => true, :description => "Invalid client"}.to_json
        end
    end

# Authentication
# --------------------------------------------------------------------------

    # Validate that the request has come from proper True Local client
    def valid_client?(request)
        (request.env["HTTP_X_FORWARDED_FOR"] == "127.0.0.1") ||
        (request.env["HTTP_X_CLIENT_IDENTIFIER"] == "<< Client Identifier Here >>") &&
        (request.env["HTTP_X_CLIENT_SECRET_KEY"] == "<< Secret Token Here >>")
    end

    # Authenticate client account information from the headers
    def authenticate(request)

        # Get the account information out of the request
        account_id = request.env["HTTP_X_CLIENT_ACCOUNT_IDENTIFIER"]
        account_token = request.env["HTTP_X_CLIENT_ACCOUNT_TOKEN"]
        device_id = request.env["HTTP_X_DEVICE_IDENTIFIER"]

        auth = {:device_id => device_id}

        if (!account_id.nil? && !account_id.empty?) && (!account_token.nil? && !account_token.empty?)

            # Get the person
            person = Person.get(account_id)

            # Validate the person
            if !person
                return auth.merge({:authenticated => false, :error => true, :description => "Person identifier not recognized.", :status => 400})
            end

            # Validate the token
            if person.user.password != account_token
                return auth.merge({:authenticated => false, :error => true, :description => "Invalid authorization token.", :status => 400})
            end

            return auth.merge({:authenticated => true, :person => person})

        else

            # Unable to authenticate
            return auth.merge({:authenticated => false})

        end

    end



# Authorization
# --------------------------------------------------------------------------



end