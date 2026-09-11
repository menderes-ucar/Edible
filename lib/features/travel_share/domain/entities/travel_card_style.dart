enum TravelCardAspect {
  square,
  portrait,
  story;

  double get ratio {
    return switch (this) {
      TravelCardAspect.square => 1,
      TravelCardAspect.portrait => 4 / 5,
      TravelCardAspect.story => 9 / 16,
    };
  }

  String get label {
    return switch (this) {
      TravelCardAspect.square => '1:1',
      TravelCardAspect.portrait => '4:5',
      TravelCardAspect.story => '9:16',
    };
  }
}

enum TravelCardTemplate {
  minimal,
  postcard,
  bold;
}
