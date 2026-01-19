# Ventricle
A heart rate reporting dashboard
[https://ventricle.de](https://ventricle.de)

## Development process notes

1. Create models, database schema, associations
* Users have many Monitoring Sessions
* Monitoring Sessions have many HeartRates
* Index User.username, making some assumptions on data integrity for time

2. Import data from CSV into database
* Wrote a fancy pants importer (with menu!) from CSV to ActiveRecord in /db/seeds.rb
* Realized this is not going to work for 15m records ~1gig, but ran it with truncated CSV so I can continue w some real data
* Decided to write a little task in /lib/tasks/csv_to_sql.rake to convert the CSV into SQL inserts because I still enjoy hand coding things, carried on while it did its thing
* Discrepency in docs "Session ID" vs "Session Id"

3. Added methods to models to return calculations needed
* Added index to HeartRate.bpm to optimize global bpm min, avg, max
* Amount of time in each heart rate zone for one monitoring session and globally courtesy of Claude
* Global one takes too long, time to go into raw sql again, 6 seconds still too long, will cache this one
* Upon careful review, Claude didn't do inclusive bounds for zones, fixed that
* Did some manual testing of results, especially the "not in zone" 1116574 of 15m is 7.4%

4. Front end
* Bootstrap and Chartkick for time
* Put global data as a summary like system monitoring
* Monitoring Sessions in order of most recent implies date is important so search by date, and also user why not, no need to paginate w/ 15m
* Add refresh the cache of zone distribution button with timestamp of cache async
* What I was working on when I ran out of time - paginate the search results, improve the cache refresh performance