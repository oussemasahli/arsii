import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class Subject {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int totalLessons;
  final int completedLessons;
  final double mastery;

  const Subject({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.totalLessons = 0,
    this.completedLessons = 0,
    this.mastery = 0.0,
  });
}

class MockQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  const MockQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

class MockData {
  MockData._();

  static const subjects = [
    Subject(
      id: 'programming',
      name: 'Programming Basics',
      description: 'Variables, control flow, functions, and OOP fundamentals',
      icon: Icons.code_rounded,
      color: AppColors.primary,
      totalLessons: 24,
      completedLessons: 18,
      mastery: 0.75,
    ),
    Subject(
      id: 'algorithms',
      name: 'Algorithms',
      description: 'Sorting, searching, recursion, and complexity analysis',
      icon: Icons.account_tree_rounded,
      color: AppColors.secondary,
      totalLessons: 20,
      completedLessons: 8,
      mastery: 0.4,
    ),
    Subject(
      id: 'data_structures',
      name: 'Data Structures',
      description: 'Arrays, linked lists, trees, graphs, and hash tables',
      icon: Icons.hub_rounded,
      color: Color(0xFF06B6D4),
      totalLessons: 18,
      completedLessons: 5,
      mastery: 0.28,
    ),
    Subject(
      id: 'databases',
      name: 'Databases',
      description: 'SQL, relational models, normalization, and NoSQL basics',
      icon: Icons.storage_rounded,
      color: AppColors.tertiary,
      totalLessons: 16,
      completedLessons: 12,
      mastery: 0.65,
    ),
    Subject(
      id: 'web',
      name: 'Web Basics',
      description: 'HTML, CSS, JavaScript, HTTP, and responsive design',
      icon: Icons.language_rounded,
      color: Color(0xFFFBBF24),
      totalLessons: 22,
      completedLessons: 3,
      mastery: 0.14,
    ),
  ];

  static const questions = [
    MockQuestion(
      question: 'What is the time complexity of binary search?',
      options: ['O(n)', 'O(log n)', 'O(n²)', 'O(1)'],
      correctIndex: 1,
    ),
    MockQuestion(
      question: 'Which data structure uses FIFO ordering?',
      options: ['Stack', 'Queue', 'Tree', 'Graph'],
      correctIndex: 1,
    ),
    MockQuestion(
      question: 'What does SQL stand for?',
      options: [
        'Structured Query Language',
        'Simple Query Logic',
        'Standard Question Language',
        'Sequential Query Lookup',
      ],
      correctIndex: 0,
    ),
    MockQuestion(
      question: 'Which HTML tag is used for the largest heading?',
      options: ['<heading>', '<h6>', '<h1>', '<head>'],
      correctIndex: 2,
    ),
    MockQuestion(
      question: 'What is a variable in programming?',
      options: [
        'A fixed constant',
        'A named storage location',
        'A type of loop',
        'A function parameter only',
      ],
      correctIndex: 1,
    ),
    MockQuestion(
      question: 'Which sorting algorithm has O(n log n) average case?',
      options: ['Bubble Sort', 'Selection Sort', 'Merge Sort', 'Insertion Sort'],
      correctIndex: 2,
    ),
  ];
}
