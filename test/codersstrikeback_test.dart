import '../bin/codersstrikeback.dart';
import 'package:test/test.dart';

void main() {
  group('pods:', () {
    test('new pod', () {
      Pod a = new Pod(0, 1, 2, 3, 4, 5, 6);
      expect(a.id, equals(0));
      expect(a.x, equals(1));
      expect(a.y, equals(2));
      expect(a.vx, equals(3));
      expect(a.vy, equals(4));
      expect(a.angle, equals(5));
      expect(a.nextCP, equals(6));
      expect(a.radius, equals(400));
    });
    test('clone pods', () {
      Pod a = new Pod(0, 0, 0, 0, 0, 0, 0);
      a.timeout = 50;
      a.shield = false;
      Pod b = a.clone();
      expect(a.timeout == b.timeout, equals(true));
      expect(a.shield == b.shield, equals(true));
      expect(a.id == b.id, equals(true));
      a.timeout = 0;
      expect(b.timeout, equals(50));
    });
    test('get angles', () {
      Pod a = new Pod(0, 0, 0, 0, 0, 0, 0);

      expect(a.getAngle(new Point(5,0)), 0);
      expect(a.getAngle(new Point(-5,0)), 180);
      expect(a.getAngle(new Point(0,5)), 90);
      expect(a.getAngle(new Point(0,-5)), 270);
    });
    test('diff angles', () {
      Pod a = new Pod(0, 0, 0, 0, 0, 0, 0);

      expect(a.diffAngle(new Point(5,0)), 0);
      expect(a.diffAngle(new Point(-5,0)), -180);
      expect(a.diffAngle(new Point(0,5)), 90);
      expect(a.diffAngle(new Point(0,-5)), -90);
    });
    test('rotate angles', () {
      Pod a = new Pod(0, 0, 0, 0, 0, 0, 0);

      a.rotate(new Point(5, 0));
      expect(a.angle, 0);

      a.rotate(new Point(5, 5));
      expect(a.angle, 18);

      a.angle = 0;
      a.rotate(new Point(5, -5));
      expect(a.angle, 360 - 18);
    });
  });
  group('checkpoints:', () {
    test('new cp', () {
      Checkpoint a = new Checkpoint(1, 4, 5);
      expect(a.id, 1);
      expect(a.x, 4);
      expect(a.y, 5);
      expect(a.radius, 200);
    });
  });
  group('collisions:', (){
    test('no collision', (){
      Pod a= new Pod(0, 0, 0, 0, 0, 0, 0);

      Checkpoint cp = new Checkpoint(1, 601, 0);

      Collision? col = a.collision(cp);
      expect(col, null);

    });
    test('t=0 collision', (){
      Pod a= new Pod(0, 0, 0, 0, 0, 0, 0);

      Checkpoint cp = new Checkpoint(1, 599, 0);

      Collision? col = a.collision(cp);
      expect(col, isNotNull);
      expect(col!.t, 0);

    });
    test('t=0.5 collision', (){
      Pod a= new Pod(0, 0, 0, 1000, 0, 0, 0);

      Checkpoint cp = new Checkpoint(1, 1100, 0);

      Collision? col = a.collision(cp);
      expect(col, isNotNull);
      expect(col!.t, 0.5);

    });
    test('t=0.5 collision at angle', (){
      Pod a= new Pod(0, 0, 0, 1000, 0, 0, 0);

      Checkpoint cp = new Checkpoint(1, 500, 599.999);

      Collision? col = a.collision(cp);
      expect(col, isNotNull);
      expect(col!.t, lessThanOrEqualTo(0.5));
      expect(col.t, greaterThanOrEqualTo(0.47));

    });
    test('moving wrong way', (){
      Pod a= new Pod(0, 0, 0, -1000, 0, 0, 0);

      Checkpoint cp = new Checkpoint(1, 500, -599.99);

      Collision? col = a.collision(cp);
      expect(col, null);

    });
    test('not fast enough', (){
      Pod a= new Pod(0, 0, 0, 100, 0, 0, 0);

      Checkpoint cp = new Checkpoint(1, 500, -599.99);

      Collision? col = a.collision(cp);
      expect(col, null);

    });


  });
}
