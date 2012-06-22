# encoding: utf-8

class TrueLocalAPI  < Sinatra::Base

    before do
        # Set the content type to be JSON
        content_type 'application/json', :charset => 'utf-8'
    end


# Get all the people
# --------------------------------------------------------------------------

    get '/:api_version/people/?' do

        # Get all the people
        people = Person.all

        # Check the authentication
        if @auth[:authenticated]
            people.extend(PeopleRepresenter::Authenticated)
        else
            people.extend(PeopleRepresenter)
        end

        people.to_json
    end

# Get a specific person, given their identifier
# --------------------------------------------------------------------------

    get '/:api_version/people/:identifier' do

        # Check the authentication params
        if @auth.has_key?(:person) && !@auth[:person].nil? && (@auth[:person].identifier == params[:identifier])

            # Show this person
            @auth[:person].show(@auth.merge({:roles => [:owner]}))

        else

            # Get the person
            person = Person.get params[:identifier]

            # Check that it's not nil
            if person.nil?
                status 400
                {:error => true, :description => "Unknown person with identifier: #{params[:identifier]}"}.to_json
            else

                # Show this person
                person.show(@auth)

            end
        end
    end


end
