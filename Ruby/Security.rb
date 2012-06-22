# @author Daniel Thorpe dan@300notes.com
# @date 4/04/2012

require 'digest'
require 'pbkdf2'

module Security

    def checkPassword(password)
        # Hash
        results = Security.hash(password, self.salt)
        self.password == results[:hash]
    end

    def securePassword(password)
        # Hash
        results = Security.hash(password)
        self.salt = results[:salt]
        self.password = results[:hash]
    end

    protected

    WORK_FACTOR = 16

    def Security.salt
        salt = SecureRandom.base64(32)
    end

    def Security.hash(password, salt = nil)

        # Create a salt if we don't have one already
        salt = Security.salt if salt == nil

        hashed = PBKDF2.new do |p|
            p.password = password
            p.salt = salt
            p.iterations = 2 ** WORK_FACTOR
            p.hash_function = OpenSSL::Digest::SHA512
        end

        {:salt => salt, :hash => hashed.hex_string}

    end

end
