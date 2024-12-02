const CHUNK_SIZE = 2 * 1024 * 1024; // 2MB per chunk
const MAX_FILE_SIZE = 100 * 1024 * 1024; // 100MB
const MAX_FILES = 5; // 最多5张图片

const progressBar = document.getElementById('progress-bar');
const statusElement = document.getElementById('status');
const resultElement = document.getElementById('result');
const uploadBox = document.getElementById('uploadBox');
const fileInput = document.getElementById('fileInput');
const uploadText = document.getElementById('uploadText');
const progress = document.getElementById('progress');
const statusContainer = document.createElement('div');
statusContainer.className = 'status-container';
document.querySelector('.container').appendChild(statusContainer);

// 检查后端状态
async function checkBackendStatus() {
    try {
        const response = await fetch('https://tc.wex.ovh/checkstatus');
        if (response.ok) {
            statusContainer.textContent = '服务正常';
            statusContainer.style.display = 'block'; // Show status element
            return true;
        } else {
            statusContainer.textContent = '服务不可用';
            statusContainer.style.display = 'block'; // Show status element
            return false;
        }
    } catch (error) {
        statusContainer.textContent = '服务不可用';
        statusContainer.style.display = 'block'; // Show status element
        return false;
    }
}

// 分片上传函数
async function uploadFileInChunks(file) {
    const totalChunks = Math.ceil(file.size / CHUNK_SIZE);
    let uploadedSize = 0;
    let result;

    for (let i = 0; i < totalChunks; i++) {
        const start = i * CHUNK_SIZE;
        const end = Math.min(file.size, start + CHUNK_SIZE);
        const chunk = file.slice(start, end);

        const formData = new FormData();
        formData.append('chunk', chunk);
        formData.append('chunkIndex', i);
        formData.append('totalChunks', totalChunks);
        formData.append('filename', file.name);

        // 上传分片
        const response = await fetch('https://tc.wex.ovh/upload_chunk', {
            method: 'POST',
            body: formData
        });

        // 更新进度
        uploadedSize += chunk.size;
        const progressPercentage = Math.min(Math.ceil((uploadedSize / file.size) * 100), 100);
        progressBar.style.width = `${progressPercentage}%`;
        progressBar.textContent = `${progressPercentage}%`;

        // 获取返回的结果
        result = await response.json();
    }

    // 返回上传的图片URL
    return result && result.status === 'ok' ? result.url : null;
}

// 处理上传按钮点击事件
document.getElementById('uploadButton').addEventListener('click', async () => {
    // 检查后端状态
    const backendAvailable = await checkBackendStatus();
    if (!backendAvailable) {
        return;
    }

    // Show progress and status
    progress.style.display = 'block';

    const files = fileInput.files;

    if (files.length === 0) {
        alert('请选择至少一张图片');
        return;
    }

    if (files.length > MAX_FILES) {
        alert(`最多只能上传 ${MAX_FILES} 张图片`);
        return;
    }

    // Clear previous results
    resultElement.innerHTML = '';
    resultElement.style.display = 'block'; // Make sure the result container is visible

    for (const file of files) {
        if (file.size > MAX_FILE_SIZE) {
            alert(`文件 ${file.name} 大小超过100MB限制`);
            continue;
        }

        progressBar.style.width = '0%';
        progressBar.textContent = '0%';

        // 上传文件
        const url = await uploadFileInChunks(file);

        if (url) {
            const imageBox = document.createElement('div');
            imageBox.classList.add('image-box');

            const img = document.createElement('img');
            img.src = url;
            img.alt = file.name;
            imageBox.appendChild(img);

            const linkBox = document.createElement('div');
            linkBox.classList.add('copy-link');
            linkBox.textContent = url;

            linkBox.addEventListener('click', () => {
                navigator.clipboard.writeText(url);
                alert('链接已复制');
            });

            imageBox.appendChild(linkBox);
            resultElement.appendChild(imageBox);
        } else {
            alert(`上传 ${file.name} 失败`);
        }
    }
});

// 处理拖拽事件
function handleDragOver(event) {
    event.preventDefault();
    uploadBox.classList.add('dragover');
}

function handleDragLeave(event) {
    event.preventDefault();
    uploadBox.classList.remove('dragover');
}

function handleDrop(event) {
    event.preventDefault();
    uploadBox.classList.remove('dragover');
    const files = event.dataTransfer.files;
    fileInput.files = files;
    if (files.length > 0) {
        document.getElementById('uploadButton').click();
    }
}

function updateUploadText() {
    const count = fileInput.files.length;
    uploadText.textContent = count > 0 ? `${count} / ${MAX_FILES} 文件已上传` : '拖拽文件到这里，或点击选择文件';
}

fileInput.addEventListener('change', updateUploadText);
uploadBox.addEventListener('click', () => fileInput.click());
uploadBox.addEventListener('dragover', handleDragOver);
uploadBox.addEventListener('dragleave', handleDragLeave);
uploadBox.addEventListener('drop', handleDrop);

// 页面加载时检查后端状态
checkBackendStatus();
