
#
#  server.py
#  这是一个更新后的 Python Flask 服务器，用于接收视频、分析并返回集锦区间。
#  此版本增加了用户注册、登录功能，并将集锦记录与特定用户关联。
#  请确保您已安装 Flask 和 moviepy: `pip install Flask moviepy`
#

import os
import random
import tempfile
import json
from flask import Flask, jsonify, request
from moviepy import VideoFileClip


app = Flask(__name__)

# 使用JSON文件作为简易数据库来存储用户数据和集锦记录
USERS_FILE = 'users.json'

def load_users():
    """从文件中加载用户数据"""
    if os.path.exists(USERS_FILE):
        with open(USERS_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {}

def save_users(users):
    """将用户数据保存到文件"""
    with open(USERS_FILE, 'w', encoding='utf-8') as f:
        json.dump(users, f, indent=4)

@app.route('/register', methods=['POST'])
def register_user():
    """
    处理用户注册请求。
    接收JSON格式的用户名和密码。
    """
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')

    if not username or not password:
        return jsonify({'error': '用户名和密码是必需的'}), 400

    users = load_users()
    if username in users:
        return jsonify({'error': '用户名已存在'}), 409

    users[username] = {
        'password': password,  # 在生产环境中，应使用哈希密码
        'highlights': []
    }
    save_users(users)
    print(f"用户 {username} 已成功注册。")
    return jsonify({'message': '用户注册成功'}), 201

@app.route('/login', methods=['POST'])
def login_user():
    """
    处理用户登录请求。
    验证用户名和密码，如果成功则返回userId。
    """
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')

    if not username or not password:
        return jsonify({'error': '用户名和密码是必需的'}), 400

    users = load_users()
    user = users.get(username)

    if user and user['password'] == password:
        # 简化处理，将用户名作为userId返回
        print(f"用户 {username} 登录成功。")
        return jsonify({'userId': username, 'message': '登录成功'}), 200
    else:
        return jsonify({'error': '用户名或密码不正确'}), 401

@app.route('/upload_video', methods=['POST'])
def upload_video():
    """
    处理视频上传，并根据传入的userId将集锦记录与用户关联。
    """
    print("收到视频上传请求。")

    # Check for userId in form data
    userId = request.form.get('userId')
    if not userId:
        return jsonify({'error': '未提供用户ID'}), 400

    if 'video' not in request.files:
        return jsonify({'error': '未提供视频文件'}), 400

    video_file = request.files['video']

    temp_dir = tempfile.gettempdir()
    temp_path = os.path.join(temp_dir, video_file.filename or 'temp_video.mp4')
    video_file.save(temp_path)
    print(f"视频已保存至临时路径: {temp_path}")

    try:
        clip = VideoFileClip(temp_path)
        duration_in_seconds = clip.duration

        fps = 30
        total_frames = int(duration_in_seconds * fps)
        print(f"视频时长: {duration_in_seconds:.2f}s, 总帧数: {total_frames}")

        if total_frames < 300:
            return jsonify({'error': '视频太短无法生成集锦。'}), 400

        highlights = []
        for _ in range(3):
            start_frame = random.randint(1, total_frames - 60)
            end_frame = start_frame + random.randint(30, 60)
            if end_frame > total_frames:
                end_frame = total_frames
            highlights.append({'startFrame': start_frame, 'endFrame': end_frame})

        # 将集锦记录与用户关联并保存
        users = load_users()
        if userId in users:
            users[userId]['highlights'].append({
                'title': f"集锦 - {video_file.filename}",
                'date': '今天',
                'location': '未知',
                'highlights': highlights,
                'duration': duration_in_seconds
            })
            save_users(users)
            print(f"用户 {userId} 的集锦记录已保存。")
        else:
            print(f"警告: 找不到用户ID {userId}。集锦记录未保存。")

        response = {'highlights': highlights}
        return jsonify(response)

    except Exception as e:
        print(f"发生错误: {e}")
        return jsonify({'error': '处理视频失败。'}), 500
    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)
            print("临时视频文件已删除。")

@app.route('/get_highlights', methods=['GET'])
def get_highlights():
    """
    根据userId返回该用户的集锦记录。
    """
    userId = request.args.get('userId')
    if not userId:
        return jsonify({'error': '未提供用户ID'}), 400

    users = load_users()
    user = users.get(userId)
    if user:
        print(f"正在为用户 {userId} 返回集锦记录。")
        return jsonify({'records': user['highlights']}), 200
    else:
        return jsonify({'error': '用户未找到'}), 404

if __name__ == '__main__':
    # 0.0.0.0 allows the server to be accessible from other devices on the same network
    app.run(host='0.0.0.0', port=5001, debug=True)
