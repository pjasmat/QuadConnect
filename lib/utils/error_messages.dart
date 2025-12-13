class ErrorMessages {
  static String getUserFriendlyError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Authentication errors
    if (errorString.contains('user not logged in') ||
        errorString.contains('not authenticated')) {
      return 'Please log in to continue.';
    }

    if (errorString.contains('wrong password') ||
        errorString.contains('invalid password')) {
      return 'Incorrect password. Please try again.';
    }

    if (errorString.contains('user not found') ||
        errorString.contains('no user record')) {
      return 'No account found with this email. Please sign up.';
    }

    if (errorString.contains('email already in use') ||
        errorString.contains('email-already-exists')) {
      return 'An account with this email already exists. Please log in instead.';
    }

    if (errorString.contains('weak password')) {
      return 'Password is too weak. Please use a stronger password.';
    }

    // Network errors
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('failed host lookup')) {
      return 'No internet connection. Please check your network and try again.';
    }

    // Firestore errors
    if (errorString.contains('permission denied') ||
        errorString.contains('insufficient permissions')) {
      return 'You don\'t have permission to perform this action.';
    }

    if (errorString.contains('not found')) {
      return 'The requested item could not be found.';
    }

    // Event-specific errors
    if (errorString.contains('full capacity')) {
      return 'This event is at full capacity. Cannot RSVP.';
    }

    if (errorString.contains('can only edit') ||
        errorString.contains('can only delete')) {
      return 'You can only modify items you created.';
    }

    // Post-specific errors
    if (errorString.contains('post content cannot be empty')) {
      return 'Please enter some content for your post.';
    }

    // Storage errors
    if (errorString.contains('object-not-found') ||
        errorString.contains('storage')) {
      return 'Unable to upload image. Please try again.';
    }

    // Generic errors
    if (errorString.contains('invalid')) {
      return 'Invalid input. Please check your information and try again.';
    }

    // Default fallback
    return 'Something went wrong. Please try again.';
  }

  static String getErrorTitle(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') ||
        errorString.contains('connection')) {
      return 'Connection Error';
    }

    if (errorString.contains('permission')) {
      return 'Permission Denied';
    }

    if (errorString.contains('not found')) {
      return 'Not Found';
    }

    if (errorString.contains('full capacity')) {
      return 'Event Full';
    }

    return 'Error';
  }

  static String getRetryAction(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') ||
        errorString.contains('connection')) {
      return 'Retry';
    }

    return 'Try Again';
  }
}

