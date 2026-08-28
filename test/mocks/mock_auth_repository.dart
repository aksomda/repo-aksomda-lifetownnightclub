import 'package:repo_aksomda_lifetownnightclub/features/auth/domain/entities/user.dart';
import 'package:repo_aksomda_lifetownnightclub/features/auth/domain/repositories/auth_repository.dart';
class MockAuthRepository implements AuthRepository { User? currentUser; bool shouldFail=false;
 @override Future<User> login({required String email,required String password}) async {if(shouldFail)throw Exception('Identifiants invalides');currentUser=const User(id:'1',name:'Somda',prename:'Clément',age:30,email:'admin@lifetown.com',telephone:'70000000',role:'admin');return currentUser!;}
 @override Future<User> register({required String name,required String prename,required int age,required String telephone,required String email,required String password}) async {currentUser=User(id:'2',name:name,prename:prename,age:age,email:email,telephone:telephone,role:'user');return currentUser!;}
 @override Future<void> logout()async{currentUser=null;} @override Future<String?> refreshToken()async=>'new-token';}
