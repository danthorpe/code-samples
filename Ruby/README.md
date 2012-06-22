Ruby
====

These are some excerpts from some recent Ruby code that I've written. The code is to power an API, it written using Sinatra and uses the Virtus and Representable gems in the model layer to provide attributes and document representation respectively.

Auth.rb
-------

These methods perform authentication on every request, and inspects the header for fields which should be present to identify the client making the request. These values correspond with the request headers configured in the Webservice code sample from iOS. Additionally, the code here will retrieve a Person object to validate the authentication, which will then get passed around as an instance method to other functions required to process a request.

People.rb
---------

This file includes the functionality of displaying Person records. If the request is display the authenticated user's own person, then it responds with the "Owner" representation of the document, which includes more sensitive information such as email addresses etc.

PersonRanking.rb
----------------

This is a simple bit of the Person model which performs updates on the Person's rank in their community - which is a feature of the product this API is written for. It calculates how much time a given person was in a territory (say, London) and sets their rank accordingly.

Security.rb
-----------

I have quite a strong interest in Cryptography, and this module shows the cryto I use to secure my user's passwords when they sign up through the API. Essentially it does 2^16 SHA512 hash functions on their salted password. Which is pretty secure from cracking by today's computers.

Pool Scoring
============

I have open sourced a ruby project I worked on for recording Pool scores at my previous employer. It is on github here: https://github.com/danthorpe/pool-scoring and live here: http://pool-scoring.heroku.com. Also, I don't think people at the office use it much anymore, because all the leaderboards are empty - as it calculates points from the games played in the last 7 days. But, there are some games on there: http://pool-scoring.heroku.com/player/daniel

This is this first Ruby project I really did, so it's not what I'd call great code or anything. It doesn't even use RSpec and I've since make my classes much smaller!