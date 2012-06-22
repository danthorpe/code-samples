Lists of Objects
================

This is a very generic UITableViewController subclass which can display lists of generic objects from a datasource. I developed it as part of a social networking application for BraveNewTalent which needed to display People, Organizations and Skill Topics, which are all very different things, but also shared some common attributes in the product's domain language.

When this class is coupled with a profile view controller (not included in the samples), which would double as a datasource, allowed the use to follow arbitrarily long relationships. For example, a profile would reveal a list of Followers (other people), displayed using this class, and tapping on a row, would push another profile view onto the navigation stack, which the user could then navigate to a list of Organizations (also displayed using this class), tapping a row would push another progile view onto the stack, etc etc.

So, by having a strong domain language enabled me to create generic controllers which can then be used in a variety of situation to display different content.