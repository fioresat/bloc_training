import 'dart:convert';
import 'dart:io';

import 'package:bloc_first_try/reddit_post.dart';
import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BlocProvider(
        create: (context) => RedditPostBloc(),
        child: const MyHomePage(),
      ),
    );
  }
}

@immutable
abstract class LoadAction {
  const LoadAction();
}

@immutable
class LoadRedditAction implements LoadAction {
  final String url;

  const LoadRedditAction({required this.url}) : super();
}

extension Subscript<T> on Iterable<T> {
  T? operator [](int index) => length > index ? elementAt(index) : null;
}

Future<Iterable<RedditPost>> getRedditPosts(String url) async {
  return HttpClient()
      .getUrl(Uri.parse(url))
      .then((request) => request.close())
      .then((response) => response.transform(utf8.decoder).join())
      .then((stringData) =>
          json.decode(stringData)['data']['children'] as List<dynamic>)
      .then((redditData) =>
          redditData.map((e) => RedditPost.fromJson(e['data'])));
}

@immutable
class FetchResult {
  final Iterable<RedditPost> redditPosts;
  final bool isRetrievedFromCache;

  const FetchResult(
      {required this.isRetrievedFromCache, required this.redditPosts});
}

class RedditPostBloc extends Bloc<LoadAction, FetchResult?> {
  final Map<String, Iterable<RedditPost>> _cache = {};

  RedditPostBloc() : super(null) {
    on<LoadRedditAction>((event, emit) async {
      final url = event.url;
      if (_cache.containsKey(url)) {
        final cachedPosts = _cache[url]!;

        final result = FetchResult(
          isRetrievedFromCache: true,
          redditPosts: cachedPosts,
        );
        emit(result);
      } else {
        final posts = await getRedditPosts(url);
        _cache[url] = posts;
        final result = FetchResult(
          isRetrievedFromCache: false,
          redditPosts: posts,
        );
        emit(result);
      }
    });
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reddit Posts'),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              context.read<RedditPostBloc>().add(
                    const LoadRedditAction(
                      url: 'https://www.reddit.com/r/flutterdev/new.json',
                    ),
                  );
            },
            child: const Text(
              'Tap to upload Reddit Posts',
              style: TextStyle(fontSize: 25),
            ),
          ),
          BlocBuilder<RedditPostBloc, FetchResult?>(
              buildWhen: (previousResult, currentResult) {
            return previousResult?.redditPosts != currentResult?.redditPosts;
          }, builder: (context, fetchResult) {
            final posts = fetchResult?.redditPosts;

            if (posts == null) {
              return const SizedBox();
            }
            return Expanded(
              child: ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final RedditPost? post = posts[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: ListTile(
                        leading: Container(
                          width: width * 0.9,
                          child: Text(
                            post!.title,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    );
                  }),
            );
          }),
        ],
      ),
    );
  }
}
