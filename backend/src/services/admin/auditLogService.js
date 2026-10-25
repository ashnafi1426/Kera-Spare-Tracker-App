import { v4 as uuidv4 } from 'uuid';

/**
 * Records an immutable audit log entry within an existing Prisma transaction.
 *
 * @param {import('@prisma/client').Prisma.TransactionClient} tx - Prisma transaction client
 * @param {Object} params
 * @param {string} params.adminId - ID of the administrator performing the action
 * @param {string|null} [params.targetUserId] - ID of the account being acted upon (if applicable)
 * @param {string} params.action - Action identifier (e.g. USER_SUSPENDED, PASSWORD_RESET)
 * @param {any} [params.oldValue] - State prior to the change (serialized to JSON)
 * @param {any} [params.newValue] - State after the change (serialized to JSON)
 * @param {string|null} [params.reason] - Stated reason or administrative note
 * @param {import('express').Request|null} [params.req] - Express request for client metadata
 * @returns {Promise<import('@prisma/client').AuditLog>}
 */
export async function record(
  tx,
  {
    adminId,
    targetUserId = null,
    action,
    oldValue = null,
    newValue = null,
    reason = null,
    req = null,
  }
) {
  if (!tx || typeof tx.auditLog?.create !== 'function') {
    throw new Error('auditLogService.record requires an active Prisma transaction client');
  }

  let ipAddress = null;
  let userAgent = null;

  if (req) {
    const forwarded = req.headers['x-forwarded-for'];
    ipAddress = forwarded
      ? forwarded.split(',')[0].trim()
      : req.ip || req.socket?.remoteAddress || null;
    userAgent = req.headers['user-agent'] || null;
  }

  return tx.auditLog.create({
    data: {
      id: uuidv4(),
      adminId,
      targetUserId,
      action,
      oldValue: oldValue ? JSON.parse(JSON.stringify(oldValue)) : null,
      newValue: newValue ? JSON.parse(JSON.stringify(newValue)) : null,
      reason,
      ipAddress: ipAddress ? String(ipAddress).substring(0, 45) : null,
      userAgent: userAgent ? String(userAgent).substring(0, 255) : null,
    },
  });
}
