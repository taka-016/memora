#!/bin/bash

echo "🔧 Running format..."
dart format .

if [ $? -ne 0 ]; then
    echo "❌ Format failed"
    exit 1
fi

echo "🔍 Running analyze..."
flutter analyze

if [ $? -ne 0 ]; then
    echo "❌ Analysis failed"
    exit 1
fi

echo "🧪 Running test..."
dart pub global run very_good_cli:very_good test

if [ $? -ne 0 ]; then
    echo "❌ Tests failed"
    exit 1
fi

echo "✅ All checks passed!"