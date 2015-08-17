# gibbon

Gibbon is an API wrapper for MailChimp's [API](http://kb.mailchimp.com/api/).

[![Build Status](https://secure.travis-ci.org/amro/gibbon.png)](http://travis-ci.org/amro/gibbon)
[![Dependency Status](https://gemnasium.com/amro/gibbon.png)](https://gemnasium.com/amro/gibbon)
##Important Notes

Gibbon now targets MailChimp API 3.0, which is substantially different from the previous API. Please use Gibbon 1.1.x if you need to use API 2.0.

Please read MailChimp's [Getting Started Guide](http://kb.mailchimp.com/api/article/api-3-overview).

##Installation

    $ gem install gibbon

##Requirements

A MailChimp account and API key. You can see your API keys [here](http://admin.mailchimp.com/account/api).

##Usage

First, create an instance Gibbon::Request:

    gibbon = Gibbon::Request.new(api_key: "your_api_key")

You can set an individual request's timeout like this:

    gibbon.timeout = 10

Now you can make requests using the resources defined in [MailChimp's docs](http://kb.mailchimp.com/api/resources). Resource IDs
are specified inline and a `CRUD` (`create`, `retrieve`, `update`, or `delete`) verb initiates the request.

    gibbon.lists.retrieve

Retrieving a specific list looks like:

    gibbon.lists(list_id).retrieve

Retrieving a specific list's members looks like:

    gibbon.lists(list_id).members.retrieve

You can also specify `headers`, `params`, and `body` when calling a `CRUD` method. For example:

    gibbon.lists.retrieve(headers: {"SomeHeader": "SomeHeaderValue"}, params: {"query_param": "query_param_value"})

Of course, `body` is only supported on `create` and `update` calls. Those map to HTTP `POST` and `PATCH` verbs.

You can set `api_key` and `timeout` globally:

    Gibbon::Request.api_key = "your_api_key"
    Gibbon::Request.timeout = 15

For example, you could set the values above in an `initializer` file in your `Rails` app (e.g. your\_app/config/initializers/gibbon.rb).

Assuming you've set an `api_key` on Gibbon, you can conveniently make API calls on the class itself:

    Gibbon::Request.lists.retrieve

You can also set the environment variable `MAILCHIMP_API_KEY` and Gibbon will use it when you create an instance:

    gibbon = Gibbon::Request.new

MailChimp's [resource documentation](http://kb.mailchimp.com/api/resources) is a list of available resources. Substitute an underscore if
a resource name contains a hyphen.

### Fetching Campaigns


    campaigns = gb.campaigns.retrieve

### Fetching Lists

Similarly, to fetch your lists

    lists = gibbon.lists.retrieve

### More Advanced Examples

List subscribers for a list:

    gibbon.lists(list_id).members.retrieve

Subscribe a member to a list:

    gibbon.lists(list_id).members.create(body: {email_address: "email_address", status: "subscribed", merge_fields: {FNAME: "First Name", LNAME: "Last Name"}})

You can also unsubscribe a member from a list:

    gibbon.lists(list_id).members(member_id).update(body: { status: "unsubscribed" })

Fetch the number of opens for a campaign

    email_stats = gibbon.reports(campaign_id).retrieve["opens"]

Overriding Gibbon's API endpoint (i.e. if using an access token from OAuth and have the `api_endpoint` from the [metadata](http://apidocs.mailchimp.com/oauth2/)):

    Gibbon::Request.api_endpoint = "https://us1.api.mailchimp.com"
    Gibbon::Request.api_key = your_access_token_or_api_key

### Interests

Interests are a little more complicated than other parts of the API, so here's an example of how you would set interests during at subscription time or update them later. The ID of the interests you want to opt in or out of must be known ahead of time so an example of how to find interest IDs is also included.

Subscribing a member to a list with specific interests up front:

    g.lists(list_id).members.create(body: {email_address: user_email_address, status: "subscribed", interests: {some_interest_id: true, another_interest_id: true}})

Updating a list member's interests:

    gibbon.lists(list_id).members(member_id).update(body: {interests: {some_interest_id: true, another_interest_id: false}})

So how do we get the interest IDs? When you query the API for a specific list member's information:

    g.lists(list_id).members(member_id).retrieve

The response looks someting like this (unrelated things removed):

    {"id"=>"...", "email_address"=>"...", ..., "interests"=>{"3def637141"=>true, "f7cc4ee841"=>false, "fcdc951b9f"=>false, "3daf3cf27d"=>true, "293a3703ed"=>false, "72370e0d1f"=>false, "d434d21a1c"=>false, "bdb1ff199f"=>false, "a54e78f203"=>false, "c4527fd018"=>false} ...}

The API returns a map of interest ID to boolean value. Now we to get interest details so we know what these interest IDs map to. Looking at [this doc page](http://kb.mailchimp.com/api/resources/lists/interest-categories/interests/lists-interests-collection), we need to do this:

    g.lists(list_id).interest_categories.retrieve

To get a list of interest categories. That gives us something like:

    {"list_id"=>"...", "categories"=>[{"list_id"=>"...", "id"=>"0ace7aa498", "title"=>"Food Preferences", ...}] ...}

In this case, we're interested in the ID of the "Food Preferences" interest, which is `0ace7aa498`. Now we can fetch the details for this interest group:

    g.lists(list_id).interest_categories("0ace7aa498").interests.retrieve

That response gives the interest data, including the ID for the interests themselves, which we can use to update a list member's interests or set them when we call the API to subscribe her or him to a list.

### Error handling

Gibbon raises an error when the API returns an error.

Gibbon::MailChimpError has the following attributes: `title`, `detail`, `body`, `raw_body`, `status_code`. Some or all of these may not be
available depending on the nature of the error.

### Migrating from Gibbon 1.x

Gibbon 2.x has different syntax from version 1.x. This is because Gibbon maps to MailChimp's API and MailChimp API 2 is different from version 3. First, the name of the primary class has changed from `API` to `Request`. And the way you pass an API key during initialization is different. A few examples below.

#### Initialization

Gibbon 1.x:

    gibbon = Gibbon::API.new("your_api_key")
    
Gibbon 2.x:

    gibbon = Gibbon::Request.new(api_key: "your_api_key")

#### Fetching Lists

Gibbon 1.x:

    gibbon.lists.list
    
Gibbon 2.x:

    gibbon.lists.retrieve

#### Fetching List Members

Gibbon 1.x:

    gibbon.lists.members({:id => list_id})
    
Gibbon 2.x:

    gibbon.lists(list_id).members.retrieve

#### Subscribing a Member to a List

Gibbon 1.x:

    gibbon.lists.subscribe({:id => list_id, :email => {:email => "email_address"}, :merge_vars => {:FNAME => "Bob", :LNAME => "Smith"}})
    
Gibbon 2.x:

    gibbon.lists(list_id).members.create(body: {email_address: "email_address", status: "subscribed", merge_fields: {FNAME: "Bob", LNAME: "Smith"}})

##Thanks

Thanks to everyone who has [contributed](https://github.com/amro/gibbon/contributors) to Gibbon's development.

##Copyright

* Copyright (c) 2010-2015 Amro Mousa. See LICENSE.txt for details.
* MailChimp (c) 2001-2015 The Rocket Science Group.
