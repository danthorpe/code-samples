Data Mapping
------------

Core Data is a very powerful persistence layer, available to Mac OS X and iOS platforms. It is commonly used to persist objects within applications and maintain an object graph either in memory, or backed by SQLite3.

A common scenario when accessing objects through an API is to map JSON into a Core Data object graph. I wrote these classes to provide a generic way to perform this, using the metadata associated with the model to map keys from the API response into the properties of the model. The ResourceMapper is a base class which acts as a factory to create classes which implement the ResourceMapper protocol. ManagedObjectResourceMapper is a generic class which maps the response of any JSON object into any Core Data model. 