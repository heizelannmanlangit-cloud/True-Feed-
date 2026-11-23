// AUTHORIZATION: what each kind of user is allowed to do.
//
//   User     -> check links, search, save, report stories
//   Reviewer -> everything a User can do, PLUS see the submitted reports
//               and mark a reported story as Unverified (or dismiss it)
//
// A person is a Reviewer when their email is in this list.
// Register an account with one of these emails to log in as a Reviewer.
// (A bigger app would keep roles in a database like Firestore.)
const List<String> reviewerEmails = [
  'reviewer@truefeed.com',
];

bool isReviewerEmail(String? email) {
  if (email == null) {
    return false;
  }
  return reviewerEmails.contains(email.trim().toLowerCase());
}
