import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:repo_aksomda_lifetownnightclub/features/menu/data/datasources/menu_local_datasource.dart';
import 'package:repo_aksomda_lifetownnightclub/features/menu/data/datasources/menu_remote_datasource.dart';
import 'package:repo_aksomda_lifetownnightclub/features/menu/data/models/menu_item_model.dart';
import 'package:repo_aksomda_lifetownnightclub/features/menu/data/repositories/menu_repository_impl.dart';
import 'package:dio/dio.dart';

class FakeRemote extends MenuRemoteDataSource { final List<MenuItemModel> items; bool fail=false; FakeRemote(this.items):super(dio:Dio()); @override Future<List<MenuItemModel>> getMenu() async {if(fail)throw Exception('offline');return items;} }
void main(){TestWidgetsFlutterBinding.ensureInitialized();setUpAll(() => Hive.init('/tmp/lifetown_hive_tests'));late Box<String> box;late MenuLocalDataSource local;setUp(()async{box=await Hive.openBox<String>('test_menu_${DateTime.now().microsecondsSinceEpoch}');local=MenuLocalDataSource(box:box);});tearDown(()async=>box.deleteFromDisk());
 test('récupère le menu depuis API',()async{final remote=FakeRemote([const MenuItemModel(id:'1',name:'Sobbra',category:'bière',price:700,available:true)]);final r=MenuRepositoryImpl(remote:remote,local:local);final result=await r.getMenu(forceRefresh:true);expect(result.single.name,'Sobbra');});
 test('met en cache les produits',()async{final remote=FakeRemote([const MenuItemModel(id:'1',name:'Brakina',category:'bière',price:700,available:true)]);final r=MenuRepositoryImpl(remote:remote,local:local);await r.getMenu(forceRefresh:true);expect(local.getMenu().single.name,'Brakina');});
 test('retourne le cache sans réseau',()async{await local.saveMenu([const MenuItemModel(id:'1',name:'Coca',category:'sucrerie',price:500,available:true)]);final remote=FakeRemote([])..fail=true;final r=MenuRepositoryImpl(remote:remote,local:local);expect((await r.getMenu()).single.name,'Coca');});
 test('retourne une erreur si API et cache sont indisponibles',()async{final remote=FakeRemote([])..fail=true;final r=MenuRepositoryImpl(remote:remote,local:local);expect(r.getMenu(forceRefresh:true),throwsException);});}
