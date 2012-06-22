# encoding: utf-8
require 'redis'
require 'deep_merge'

class Person

    # Update the properties of the person
    # such as their rank
    def update

        # Get the epoch offsets
        since = CommunityRank.since_offsets

        # Get the position objects since the last time it was calculated
        positions = get_positions({:since => since[CommunityRank.duration_week]})

        # Create a hash
        durations = {}

        self.community_ranks.each do |community_rank|

            # Set the identifier
            identifier = community_rank.community.identifier

            # Create a new hash
            durations[identifier] = {}

            # Get the durations in the community for each device
            positions.each do |device_id, device_positions|
                durations[identifier][device_id] = community_rank.community.time_spent_in_community(device_positions)
            end

            # Set the maximum duration in the CommunityRank
            community_rank.duration ||= {}
            community_rank.duration[CommunityRank.duration_week] = durations[identifier].values.max

            # Update the rank
            community_rank.update

        end

        # Persist the model
        self.put

    end

end
