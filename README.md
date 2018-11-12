# Savour Deals iOS

<span span style="display:block;text-align:center">
  <img src="https://firebasestorage.googleapis.com/v0/b/savour-deals.appspot.com/o/Savour_Deals_FullColor.png?alt=media&token=8b67f1ae-cbc5-4709-becd-844ea51b7574" width="60%">
</span>

Savour Deals is an iOS app which connects users, free of charge, to exclusive deals at restaurants, bars, and coffee shops. We allow vendors to have a loyalty program on their page and you can check-in and earn points with a click of a button. Our deals use location services to organize them by how close they are to you, making it easy to decide where to grab lunch or pick up a morning coffee. We are currently serving Minneapolis/St.Paul, MN and Fargo/Moorhead ND areas!
<br>
<br>
<span span style="display:block;text-align:center">
  <img style="padding:10px" src="https://firebasestorage.googleapis.com/v0/b/savour-deals.appspot.com/o/Assets%2FappPhotos%2FSimulator%20Screen%20Shot%20-%20iPhone%20X%20-%202018-08-21%20at%2021.20.29.png?alt=media&token=596e79df-56c0-42cf-b6cf-5447b0d9ad11" width="15%">
  <img style="padding:10px" src="https://firebasestorage.googleapis.com/v0/b/savour-deals.appspot.com/o/Assets%2FappPhotos%2FSimulator%20Screen%20Shot%20-%20iPhone%20X%20-%202018-08-21%20at%2021.39.47.png?alt=media&token=eb3a091f-c91c-4e4b-ade8-36b2253ce8f4" width="15%">
  <img style="padding:10px" src="https://firebasestorage.googleapis.com/v0/b/savour-deals.appspot.com/o/Assets%2FappPhotos%2FSimulator%20Screen%20Shot%20-%20iPhone%20X%20-%202018-08-21%20at%2021.39.53.png?alt=media&token=dea6d0bf-465b-4f40-b63a-b8cf90ff5eae" width="15%">
  <img style="padding:10px" src="https://firebasestorage.googleapis.com/v0/b/savour-deals.appspot.com/o/Assets%2FappPhotos%2FSimulator%20Screen%20Shot%20-%20iPhone%20X%20-%202018-08-21%20at%2021.40.10.png?alt=media&token=7951e85f-26f7-4ff0-980b-76e2dc34365d" width="15%">
  <img style="padding:10px" src="https://firebasestorage.googleapis.com/v0/b/savour-deals.appspot.com/o/Assets%2FappPhotos%2FSimulator%20Screen%20Shot%20-%20iPhone%20X%20-%202018-08-21%20at%2021.40.15.png?alt=media&token=0bc45445-70e1-43ea-8849-5435dc4805fc" width="15%">
</span>
<br>
<br>

We only charge local vendors a small fee when a deal is redeemed, making it a business friendly price that can scale with their business needs! 

Find us on the [Apple App Store](https://itunes.apple.com/us/app/savour-deals/id1294994353?ls=1&mt=8).

For more information about how we are helping promote local businesses, visit our [website](https://www.savourdeals.com/).

Savour was developed with Swift and uses a variety of tools and resources to implement the various features of the app:
- Firebase 
	- Realtime Database (NoSQL database persistence). RTDB is used to store most of the data for Savour Deals. It is where we keep information about deals, users and vendors. For example, storing redemption times of a deal to log when a user uses a specific deal and how keeping track of how many times a deal has been redeemed.
	- Firebase Cloud Functions. Cloud functions allows us to automate some of the functionality of our app, such as updating redemptions counts of deals and charging vendors.
	- Firebase Authentication. Authentication is seamlessly integrated with Facebook and allows for easy account creation and managment.
	- GeoFire for location based queries. Because our app heavily relies on location services to display deals, an efficient query system was necessary to be data efficient when gathering deals and vendors near a user. GeoFire provides an api to query within a radius of a user and retrieve information about only the vendors within that radius. As we scale and expand to more cities, this will help will efficiency of the app.
