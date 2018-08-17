This repository holds examples of production code that I have written.

* 'Flag-conversations' 
  - Contains the Ruby on Rails code written for a tutoring platform to help identify and stop tutors who attempt to work with students outside the platform. 
  - Flags a conversation when a message is sent containing certain blacklist criteria (phone numbers, email addresses, keywords). This flag is visible to admins, who can view all conversations. 
  - Includes the ability for admins to filter the conversations to view only those which are flagged with an alert, as well as sort them by oldest or newest activity.
  - Also gives admins the ability to remove an alert flag from a conversation.
