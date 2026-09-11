import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../data/datasources/content_rating_remote_data_source.dart';
import '../../domain/entities/content_rating_summary.dart';

class ContentRatingCard extends StatefulWidget {
 const ContentRatingCard({required this.contentId,required this.isVisited,super.key});
 final String contentId; final bool isVisited;
 @override State<ContentRatingCard> createState()=>_ContentRatingCardState();
}
class _ContentRatingCardState extends State<ContentRatingCard>{
 final _data=const ContentRatingRemoteDataSource();
 ContentRatingSummary _summary=const ContentRatingSummary(average:0,count:0);
 bool _busy=false;
 @override void initState(){super.initState();_load();}
 Future<void> _load()async{try{final s=await _data.load(widget.contentId);if(mounted)setState(()=>_summary=s);}catch(_){}}
 Future<void> _rate(int value)async{
  final auth=context.read<AuthProvider>();
  if(auth.isGuest){context.push(AppRoutes.login);return;}
  if (!widget.isVisited) {
   ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
     content: Text(
      context.l10n.text('markVisitedBeforeRating'),
     ),
    ),
   );
   return;
  }
  setState(()=>_busy=true);
  try{await _data.rate(widget.contentId,value);await _load();}
  finally{if(mounted)setState(()=>_busy=false);}
 }
 @override Widget build(BuildContext context)=>Card(
  child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Row(children:[
    const Icon(Icons.star_rounded),const SizedBox(width:8),
    Text(_summary.count==0?'—':_summary.average.toStringAsFixed(1),style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w900)),
    const SizedBox(width:6),Text('(${_summary.count})'),
   ]),
   const SizedBox(height:10),
   Row(children:List.generate(5,(i){
    final value=i+1;final selected=(_summary.myRating??0)>=value;
    return IconButton(onPressed:_busy?null:()=>_rate(value),icon:Icon(selected?Icons.star_rounded:Icons.star_border_rounded),tooltip:'$value/5');
   })),
  ])),
 );
}
