class PostMilePoint {
  final double longitude;
  final double latitude;
  final double postMile;

  PostMilePoint(this.longitude, this.latitude, this.postMile);

  List<double> get point => [longitude, latitude];
}

