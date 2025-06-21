#!/bin/bash

echo "🔧 Running dart format..."
dart format .

if [ $? -ne 0 ]; then
    echo "❌ Format failed"
    exit 1
fi

echo "🔍 Running flutter analyze..."
flutter analyze

if [ $? -ne 0 ]; then
    echo "❌ Analysis failed"
    exit 1
fi

echo "🧪 Running flutter test..."
flutter test

if [ $? -ne 0 ]; then
    echo "❌ Tests failed"
    exit 1
fi

echo "✅ All checks passed!"